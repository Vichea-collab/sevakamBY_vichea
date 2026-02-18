import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../data/datasources/remote/order_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/order_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/provider.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/order_repository.dart';
import 'app_role_state.dart' show AppRole, AppRoleState;

class OrderState {
  static const int _pageSize = 10;

  static final OrderRepository _repository = OrderRepositoryImpl(
    remoteDataSource: OrderRemoteDataSource(
      BackendApiClient(
        baseUrl: AppEnv.apiBaseUrl(),
        bearerToken: AppEnv.apiAuthToken(),
      ),
    ),
  );

  static final ValueNotifier<List<OrderItem>> finderOrders = ValueNotifier(
    const <OrderItem>[],
  );
  static final ValueNotifier<List<ProviderOrderItem>> providerOrders =
      ValueNotifier(const <ProviderOrderItem>[]);
  static final ValueNotifier<PaginationMeta> finderPagination = ValueNotifier(
    const PaginationMeta.initial(limit: _pageSize),
  );
  static final ValueNotifier<PaginationMeta> providerPagination = ValueNotifier(
    const PaginationMeta.initial(limit: _pageSize),
  );
  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<bool> realtimeActive = ValueNotifier(false);

  static bool _initialized = false;
  static String _backendToken = AppEnv.apiAuthToken().trim();
  static Future<bool>? _tokenRefreshInFlight;
  static bool _realtimeEnabled = const bool.fromEnvironment(
    'ORDER_REALTIME_STREAM',
    defaultValue: true,
  );
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _ordersSubscription;
  static AppRole? _streamRole;
  static String _streamUid = '';

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    await refreshCurrentRole();
  }

  static bool get realtimeEnabled => _realtimeEnabled;

  static Future<void> setRealtimeEnabled(bool enabled) async {
    _realtimeEnabled = enabled;
    if (!enabled) {
      await _stopRealtime();
      return;
    }
    await refreshCurrentRole();
  }

  static void setBackendToken(String token) {
    _backendToken = token.trim();
    _repository.setBearerToken(_backendToken);
    if (_backendToken.isEmpty) {
      unawaited(_stopRealtime());
      finderOrders.value = const <OrderItem>[];
      providerOrders.value = const <ProviderOrderItem>[];
      finderPagination.value = const PaginationMeta.initial(limit: _pageSize);
      providerPagination.value = const PaginationMeta.initial(limit: _pageSize);
      return;
    }
    unawaited(refreshCurrentRole());
  }

  static Future<void> refreshCurrentRole({
    bool forceNetwork = false,
    int? page,
  }) async {
    final isProvider = AppRoleState.isProvider;
    final fallbackPage = isProvider
        ? providerPagination.value.page
        : finderPagination.value.page;
    final targetPage = _normalizedPage(page ?? fallbackPage);

    if (!forceNetwork && targetPage == 1) {
      final usingRealtime = await _startRealtimeIfAvailable();
      if (usingRealtime) return;
    }
    if (isProvider) {
      await refreshProviderOrders(page: targetPage);
    } else {
      await refreshFinderOrders(page: targetPage);
    }
  }

  static Future<void> refreshFinderOrders({
    int? page,
    int limit = _pageSize,
    bool allowRoleFallback = true,
  }) async {
    final targetPage = page ?? _normalizedPage(finderPagination.value.page);
    loading.value = true;
    try {
      final ready = await _ensureBackendToken();
      if (!ready) {
        _resetFinderOrders(targetPage, limit);
        return;
      }
      final result = await _runWithAuthRetry(
        () => _repository.fetchFinderOrders(page: targetPage, limit: limit),
      );
      finderOrders.value = result.items;
      finderPagination.value = result.pagination;
      if (AppRoleState.isProvider) {
        AppRoleState.setProvider(false);
      }
    } on BackendApiException catch (error) {
      if (_isRoleForbidden(error) && allowRoleFallback) {
        AppRoleState.setProvider(true);
        await refreshProviderOrders(
          page: _normalizedPage(providerPagination.value.page),
          limit: limit,
          allowRoleFallback: false,
        );
        return;
      }
      debugPrint('OrderState.refreshFinderOrders failed: $error');
      _resetFinderOrders(targetPage, limit);
    } catch (error) {
      debugPrint('OrderState.refreshFinderOrders failed: $error');
      _resetFinderOrders(targetPage, limit);
    } finally {
      loading.value = false;
    }
  }

  static Future<void> refreshProviderOrders({
    int? page,
    int limit = _pageSize,
    bool allowRoleFallback = true,
  }) async {
    final targetPage = page ?? _normalizedPage(providerPagination.value.page);
    loading.value = true;
    try {
      final ready = await _ensureBackendToken();
      if (!ready) {
        _resetProviderOrders(targetPage, limit);
        return;
      }
      final result = await _runWithAuthRetry(
        () => _repository.fetchProviderOrders(page: targetPage, limit: limit),
      );
      providerOrders.value = result.items;
      providerPagination.value = result.pagination;
      if (!AppRoleState.isProvider) {
        AppRoleState.setProvider(true);
      }
    } on BackendApiException catch (error) {
      if (_isRoleForbidden(error) && allowRoleFallback) {
        AppRoleState.setProvider(false);
        await refreshFinderOrders(
          page: _normalizedPage(finderPagination.value.page),
          limit: limit,
          allowRoleFallback: false,
        );
        return;
      }
      debugPrint('OrderState.refreshProviderOrders failed: $error');
      _resetProviderOrders(targetPage, limit);
    } catch (error) {
      debugPrint('OrderState.refreshProviderOrders failed: $error');
      _resetProviderOrders(targetPage, limit);
    } finally {
      loading.value = false;
    }
  }

  static void _resetFinderOrders(int page, int limit) {
    finderOrders.value = const <OrderItem>[];
    finderPagination.value = PaginationMeta(
      page: page,
      limit: limit,
      totalItems: 0,
      totalPages: 0,
      hasPrevPage: false,
      hasNextPage: false,
    );
  }

  static void _resetProviderOrders(int page, int limit) {
    providerOrders.value = const <ProviderOrderItem>[];
    providerPagination.value = PaginationMeta(
      page: page,
      limit: limit,
      totalItems: 0,
      totalPages: 0,
      hasPrevPage: false,
      hasNextPage: false,
    );
  }

  static Future<bool> _ensureBackendToken() async {
    if (_backendToken.isNotEmpty) return true;
    return _refreshBackendToken(force: false);
  }

  static Future<bool> _refreshBackendToken({required bool force}) async {
    if (!force && _backendToken.isNotEmpty) return true;
    final inFlight = _tokenRefreshInFlight;
    if (inFlight != null) return inFlight;

    final future = _refreshBackendTokenInternal(force: force);
    _tokenRefreshInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_tokenRefreshInFlight, future)) {
        _tokenRefreshInFlight = null;
      }
    }
  }

  static Future<bool> _refreshBackendTokenInternal({
    required bool force,
  }) async {
    if (!FirebaseBootstrap.isConfigured) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    try {
      final refreshed = (await user.getIdToken(force) ?? '').trim();
      if (refreshed.isEmpty) return false;
      _backendToken = refreshed;
      _repository.setBearerToken(refreshed);
      return true;
    } catch (error) {
      debugPrint('OrderState token refresh failed: $error');
      return false;
    }
  }

  static Future<T> _runWithAuthRetry<T>(Future<T> Function() task) async {
    try {
      return await task();
    } on BackendApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      final refreshed = await _refreshBackendToken(force: true);
      if (!refreshed) rethrow;
      return task();
    }
  }

  static bool _isRoleForbidden(BackendApiException error) {
    if (error.statusCode != 403) return false;
    return error.message.trim().toLowerCase().contains('forbidden (role)');
  }

  static Future<OrderItem> createFinderOrder(BookingDraft draft) async {
    final created = await _repository.createFinderOrder(draft);
    if (_normalizedPage(finderPagination.value.page) == 1) {
      final next = [created, ...finderOrders.value];
      finderOrders.value = next.take(_pageSize).toList();
    }
    finderPagination.value = _withAdjustedTotalItems(
      finderPagination.value,
      delta: 1,
    );
    return created;
  }

  static Future<BookingPriceQuote> quoteFinderOrder(BookingDraft draft) async {
    final ready = await _ensureBackendToken();
    if (!ready) return BookingPriceQuote.fromDraft(draft);
    try {
      return await _runWithAuthRetry(() => _repository.quoteFinderOrder(draft));
    } catch (_) {
      return BookingPriceQuote.fromDraft(draft);
    }
  }

  static Future<List<HomeAddress>> fetchSavedAddresses() {
    return _repository.fetchSavedAddresses();
  }

  static Future<HomeAddress> createSavedAddress({
    required HomeAddress address,
  }) {
    return _repository.createSavedAddress(address: address);
  }

  static Future<KhqrPaymentSession> createKhqrPaymentSession({
    required String orderId,
  }) {
    return _repository.createKhqrPaymentSession(orderId: orderId);
  }

  static Future<KhqrPaymentVerification> verifyKhqrPayment({
    required String orderId,
    String transactionId = '',
  }) async {
    final result = await _repository.verifyKhqrPayment(
      orderId: orderId,
      transactionId: transactionId,
    );
    finderOrders.value = _replaceFinder(result.order);
    return result;
  }

  static Future<OrderItem> updateFinderOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final updated = await _repository.updateFinderOrderStatus(
      orderId: orderId,
      status: status,
    );
    finderOrders.value = _replaceFinder(updated);
    return updated;
  }

  static void replaceFinderOrderLocal(OrderItem item) {
    finderOrders.value = _replaceFinder(item);
  }

  static Future<ProviderOrderItem> updateProviderOrderStatus({
    required String orderId,
    required ProviderOrderState state,
  }) async {
    final updated = await _repository.updateProviderOrderStatus(
      orderId: orderId,
      state: state,
    );
    providerOrders.value = _replaceProvider(updated);
    return updated;
  }

  static void replaceProviderOrderLocal(ProviderOrderItem item) {
    providerOrders.value = _replaceProvider(item);
  }

  static List<OrderItem> _replaceFinder(OrderItem item) {
    final index = finderOrders.value.indexWhere((row) => row.id == item.id);
    if (index < 0) {
      return [item, ...finderOrders.value];
    }
    final next = List<OrderItem>.from(finderOrders.value);
    next[index] = item;
    return next;
  }

  static List<ProviderOrderItem> _replaceProvider(ProviderOrderItem item) {
    final index = providerOrders.value.indexWhere((row) => row.id == item.id);
    if (index < 0) {
      return [item, ...providerOrders.value];
    }
    final next = List<ProviderOrderItem>.from(providerOrders.value);
    next[index] = item;
    return next;
  }

  static Future<bool> _startRealtimeIfAvailable() async {
    if (!_realtimeEnabled || !FirebaseBootstrap.isConfigured) return false;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final role = AppRoleState.role.value;
    if (role == AppRole.provider) {
      // Provider flow relies on backend aggregation (incoming + assigned orders).
      // Firestore security rules commonly deny broad provider live queries.
      return false;
    }
    final uid = user.uid;
    final alreadyBound =
        _ordersSubscription != null && _streamRole == role && _streamUid == uid;
    if (alreadyBound) {
      if (realtimeActive.value) return true;
      await _stopRealtime();
    }

    await _stopRealtime();
    _streamRole = role;
    _streamUid = uid;

    final query = FirebaseFirestore.instance
        .collection('orders')
        .where('finderUid', isEqualTo: uid)
        .limit(_pageSize)
        .snapshots();

    _ordersSubscription = query.listen(
      (snapshot) {
        final rows = snapshot.docs.map((doc) {
          final row = Map<String, dynamic>.from(doc.data());
          row['id'] ??= doc.id;
          return row;
        }).toList()..sort((a, b) => _createdAtMillis(b) - _createdAtMillis(a));

        finderOrders.value = rows.map(_toFinderOrder).toList();
        finderPagination.value = PaginationMeta(
          page: 1,
          limit: _pageSize,
          totalItems: rows.length,
          totalPages: rows.isEmpty ? 0 : 1,
          hasPrevPage: false,
          hasNextPage: false,
        );
        realtimeActive.value = true;
      },
      onError: (error) {
        debugPrint('OrderState realtime stream failed, switching to API');
        debugPrint('$error');
        if (_isPermissionDeniedError(error)) {
          _realtimeEnabled = false;
          debugPrint(
            'OrderState realtime disabled for this session due to Firestore permission rules.',
          );
        }
        realtimeActive.value = false;
        unawaited(_stopRealtime());
        unawaited(refreshCurrentRole(forceNetwork: true));
      },
    );
    realtimeActive.value = true;
    return true;
  }

  static Future<void> _stopRealtime() async {
    await _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _streamRole = null;
    _streamUid = '';
    realtimeActive.value = false;
  }

  static bool _isPermissionDeniedError(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('permission-denied') ||
        message.contains('permission denied')) {
      return true;
    }

    final dynamicError = error as dynamic;
    final code = (dynamicError.code ?? '').toString().toLowerCase();
    if (code == 'permission-denied' || code == 'permission_denied') {
      return true;
    }

    final details = (dynamicError.message ?? '').toString().toLowerCase();
    return details.contains('permission-denied') ||
        details.contains('permission denied');
  }

  static int _normalizedPage(int page) {
    if (page < 1) return 1;
    return page;
  }

  static PaginationMeta _withAdjustedTotalItems(
    PaginationMeta current, {
    required int delta,
  }) {
    final totalItems = (current.totalItems + delta).clamp(0, 99999999);
    final limit = current.limit <= 0 ? _pageSize : current.limit;
    final totalPages = totalItems == 0
        ? 0
        : ((totalItems + limit - 1) ~/ limit);
    final page = current.page.clamp(1, totalPages == 0 ? 1 : totalPages);
    return PaginationMeta(
      page: page,
      limit: limit,
      totalItems: totalItems,
      totalPages: totalPages,
      hasPrevPage: totalPages > 0 && page > 1,
      hasNextPage: totalPages > 0 && page < totalPages,
    );
  }

  static int _createdAtMillis(Map<String, dynamic> row) {
    final value = row['createdAt'];
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return (seconds * 1000).round();
    }
    return 0;
  }

  static OrderItem _toFinderOrder(Map<String, dynamic> row) {
    final provider = ProviderItem(
      uid: (row['providerUid'] ?? '').toString(),
      name: (row['providerName'] ?? '').toString().trim().isEmpty
          ? 'Service Provider'
          : (row['providerName'] ?? '').toString().trim(),
      role: (row['providerRole'] ?? '').toString().trim().isEmpty
          ? (row['categoryName'] ?? 'General').toString()
          : (row['providerRole'] ?? '').toString(),
      rating: _toDouble(row['providerRating'], fallback: 4.0),
      imagePath: _safeAssetPath(row['providerImagePath']),
      accentColor: const Color(0xFFEAF1FF),
      providerType: _providerType((row['providerType'] ?? '').toString()),
      companyName: (row['providerCompanyName'] ?? '').toString(),
      maxWorkers: _providerMaxWorkers(
        row['providerMaxWorkers'],
        _providerType((row['providerType'] ?? '').toString()),
      ),
    );
    final address = HomeAddress(
      id: (row['id'] ?? '').toString(),
      label: (row['addressLabel'] ?? 'Home').toString(),
      mapLink: (row['addressMapLink'] ?? '').toString(),
      street: (row['addressStreet'] ?? '').toString(),
      city: (row['addressCity'] ?? '').toString(),
    );
    final preferredDate = _toDateTime(row['preferredDate']);
    final bookedAt = _toDateTime(row['createdAt']);
    final timeline = _timelineFromRow(row, fallbackBookedAt: bookedAt);
    return OrderItem(
      id: (row['id'] ?? '').toString(),
      provider: provider,
      serviceName: (row['serviceName'] ?? 'Service').toString(),
      address: address,
      hours: _toInt(row['hours'], fallback: 1),
      workers: _toInt(row['workers'], fallback: 1),
      homeType: _homeTypeFromStorage((row['homeType'] ?? '').toString()),
      additionalService: (row['additionalService'] ?? '').toString(),
      bookedAt: bookedAt,
      scheduledAt: preferredDate,
      timeRange: (row['preferredTimeSlot'] ?? '').toString(),
      paymentMethod: _paymentMethodFromStorage(
        (row['paymentMethod'] ?? '').toString(),
      ),
      subtotal: _toDouble(row['subtotal']),
      processingFee: _toDouble(row['processingFee']),
      discount: _toDouble(row['discount']),
      status: _orderStatusFromStorage((row['status'] ?? '').toString()),
      timeline: timeline,
    );
  }

  static String _safeAssetPath(dynamic value) {
    final path = (value ?? '').toString().trim();
    if (path.startsWith('assets/')) return path;
    return 'assets/images/profile.jpg';
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim()) ?? DateTime.now();
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return DateTime.now();
  }

  static DateTime? _toDateTimeOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toLocal();
    if (value is DateTime) return value.toLocal();
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }
    if (value is Map && value['_seconds'] is num) {
      final seconds = value['_seconds'] as num;
      return DateTime.fromMillisecondsSinceEpoch((seconds * 1000).round());
    }
    return null;
  }

  static OrderStatusTimeline _timelineFromRow(
    Map<String, dynamic> row, {
    DateTime? fallbackBookedAt,
  }) {
    final source = row['statusTimeline'];
    DateTime? read(String key) {
      if (source is! Map) return null;
      return _toDateTimeOrNull(source[key]);
    }

    var completedAt = read('completedAt');
    var cancelledAt = read('cancelledAt');
    var declinedAt = read('declinedAt');
    final updatedAt = _toDateTimeOrNull(row['updatedAt']);
    final status = (row['status'] ?? '').toString().trim().toLowerCase();
    if (status == 'completed') completedAt ??= updatedAt;
    if (status == 'cancelled') cancelledAt ??= updatedAt;
    if (status == 'declined') declinedAt ??= updatedAt;

    return OrderStatusTimeline(
      bookedAt: read('bookedAt') ?? fallbackBookedAt,
      onTheWayAt: read('onTheWayAt'),
      startedAt: read('startedAt'),
      completedAt: completedAt,
      cancelledAt: cancelledAt,
      declinedAt: declinedAt,
    );
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    final parsed = int.tryParse((value ?? '').toString());
    return parsed ?? fallback;
  }

  static double _toDouble(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    final parsed = double.tryParse((value ?? '').toString());
    return parsed ?? fallback;
  }

  static String _providerType(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'company') return 'company';
    return 'individual';
  }

  static int _providerMaxWorkers(dynamic value, String providerType) {
    if (providerType != 'company') return 1;
    if (value is int && value > 0) return value;
    if (value is num && value > 0) return value.toInt();
    final parsed = int.tryParse((value ?? '').toString().trim());
    if (parsed != null && parsed > 0) return parsed;
    return 1;
  }

  static OrderStatus _orderStatusFromStorage(String status) {
    switch (status.trim().toLowerCase()) {
      case 'on_the_way':
        return OrderStatus.onTheWay;
      case 'started':
        return OrderStatus.started;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'declined':
        return OrderStatus.declined;
      case 'booked':
      default:
        return OrderStatus.booked;
    }
  }

  static PaymentMethod _paymentMethodFromStorage(String value) {
    switch (value.trim().toLowerCase()) {
      case 'bank_account':
      case 'bank account':
        return PaymentMethod.bankAccount;
      case 'cash':
        return PaymentMethod.cash;
      case 'khqr':
        return PaymentMethod.khqr;
      default:
        return PaymentMethod.creditCard;
    }
  }

  static HomeType _homeTypeFromStorage(String value) {
    switch (value.trim().toLowerCase()) {
      case 'flat':
        return HomeType.flat;
      case 'villa':
        return HomeType.villa;
      case 'office':
        return HomeType.office;
      case 'apartment':
      default:
        return HomeType.apartment;
    }
  }
}
