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
import '../../domain/entities/provider.dart';
import '../../domain/entities/provider_portal.dart';
import '../../domain/repositories/order_repository.dart';
import 'app_role_state.dart' show AppRole, AppRoleState;

class OrderState {
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
  static final ValueNotifier<bool> loading = ValueNotifier(false);
  static final ValueNotifier<bool> realtimeActive = ValueNotifier(false);

  static bool _initialized = false;
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
    _repository.setBearerToken(token);
    if (token.trim().isEmpty) {
      unawaited(_stopRealtime());
      finderOrders.value = const <OrderItem>[];
      providerOrders.value = const <ProviderOrderItem>[];
      return;
    }
    unawaited(refreshCurrentRole());
  }

  static Future<void> refreshCurrentRole({bool forceNetwork = false}) async {
    if (!forceNetwork) {
      final usingRealtime = await _startRealtimeIfAvailable();
      if (usingRealtime) return;
    }
    if (AppRoleState.isProvider) {
      await refreshProviderOrders();
    } else {
      await refreshFinderOrders();
    }
  }

  static Future<void> refreshFinderOrders() async {
    loading.value = true;
    try {
      finderOrders.value = await _repository.fetchFinderOrders();
    } catch (error) {
      debugPrint('OrderState.refreshFinderOrders failed: $error');
      finderOrders.value = const <OrderItem>[];
    } finally {
      loading.value = false;
    }
  }

  static Future<void> refreshProviderOrders() async {
    loading.value = true;
    try {
      providerOrders.value = await _repository.fetchProviderOrders();
    } catch (error) {
      debugPrint('OrderState.refreshProviderOrders failed: $error');
      providerOrders.value = const <ProviderOrderItem>[];
    } finally {
      loading.value = false;
    }
  }

  static Future<OrderItem> createFinderOrder(BookingDraft draft) async {
    final created = await _repository.createFinderOrder(draft);
    finderOrders.value = [created, ...finderOrders.value];
    return created;
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

    _ordersSubscription = FirebaseFirestore.instance
        .collection('orders')
        .limit(250)
        .snapshots()
        .listen(
          (snapshot) {
            final rows = snapshot.docs.map((doc) {
              final row = Map<String, dynamic>.from(doc.data());
              row['id'] ??= doc.id;
              return row;
            }).toList();

            if (role == AppRole.finder) {
              final finderRows =
                  rows
                      .where(
                        (row) =>
                            (row['finderUid'] ?? '').toString().trim() == uid,
                      )
                      .toList()
                    ..sort((a, b) => _createdAtMillis(b) - _createdAtMillis(a));
              finderOrders.value = finderRows.map(_toFinderOrder).toList();
            } else {
              final providerRows =
                  rows.where((row) {
                      final providerUid = (row['providerUid'] ?? '')
                          .toString()
                          .trim();
                      final status = (row['status'] ?? '')
                          .toString()
                          .trim()
                          .toLowerCase();
                      if (providerUid == uid) return true;
                      return providerUid.isEmpty && status == 'booked';
                    }).toList()
                    ..sort((a, b) => _createdAtMillis(b) - _createdAtMillis(a));
              providerOrders.value = providerRows
                  .map(_toProviderOrder)
                  .toList();
            }
            realtimeActive.value = true;
          },
          onError: (error) {
            debugPrint('OrderState realtime stream failed, switching to API');
            debugPrint('$error');
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
    );
    final address = HomeAddress(
      id: (row['id'] ?? '').toString(),
      label: (row['addressLabel'] ?? 'Home').toString(),
      mapLink: (row['addressMapLink'] ?? '').toString(),
      street: (row['addressStreet'] ?? '').toString(),
      city: (row['addressCity'] ?? '').toString(),
    );
    final preferredDate = _toDateTime(row['preferredDate']);
    return OrderItem(
      id: (row['id'] ?? '').toString(),
      provider: provider,
      serviceName: (row['serviceName'] ?? 'Service').toString(),
      address: address,
      hours: _toInt(row['hours'], fallback: 1),
      workers: _toInt(row['workers'], fallback: 1),
      homeType: _homeTypeFromStorage((row['homeType'] ?? '').toString()),
      additionalService: (row['additionalService'] ?? '').toString(),
      bookedAt: _toDateTime(row['createdAt']),
      scheduledAt: preferredDate,
      timeRange: (row['preferredTimeSlot'] ?? '').toString(),
      paymentMethod: _paymentMethodFromStorage(
        (row['paymentMethod'] ?? '').toString(),
      ),
      subtotal: _toDouble(row['subtotal']),
      processingFee: _toDouble(row['processingFee']),
      discount: _toDouble(row['discount']),
      status: _orderStatusFromStorage((row['status'] ?? '').toString()),
    );
  }

  static ProviderOrderItem _toProviderOrder(Map<String, dynamic> row) {
    final preferredDate = _toDateTime(row['preferredDate']);
    final inputs = <String, String>{};
    final rawInputs = row['serviceFields'];
    if (rawInputs is Map) {
      for (final entry in rawInputs.entries) {
        inputs[entry.key.toString()] = (entry.value ?? '').toString();
      }
    }
    final address =
        '${(row['addressStreet'] ?? '').toString()}, ${(row['addressCity'] ?? '').toString()}'
            .trim();
    return ProviderOrderItem(
      id: (row['id'] ?? '').toString(),
      clientName: (row['finderName'] ?? 'Finder').toString(),
      clientPhone: (row['finderPhone'] ?? '').toString(),
      category: (row['categoryName'] ?? '').toString(),
      serviceName: (row['serviceName'] ?? '').toString(),
      address: address.replaceAll(RegExp(r'^,\s*|\s*,\s*$'), ''),
      addressLink: (row['addressMapLink'] ?? '').toString(),
      scheduleDate: _formatDate(preferredDate),
      scheduleTime: (row['preferredTimeSlot'] ?? '').toString(),
      workers: _toInt(row['workers'], fallback: 1),
      hours: _toInt(row['hours'], fallback: 1),
      homeType: (row['homeType'] ?? '').toString(),
      paymentMethod: (row['paymentMethod'] ?? '').toString(),
      additionalService: (row['additionalService'] ?? '').toString(),
      finderNote: (row['finderNote'] ?? '').toString(),
      serviceInputs: inputs,
      subtotal: _toDouble(row['subtotal']),
      processingFee: _toDouble(row['processingFee']),
      discount: _toDouble(row['discount']),
      total: _toDouble(row['total']),
      state: _providerStateFromStorage((row['status'] ?? '').toString()),
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

  static String _formatDate(DateTime value) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[(value.weekday - 1).clamp(0, 6)];
    final month = months[(value.month - 1).clamp(0, 11)];
    return '$weekday, $month ${value.day}';
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
      case 'declined':
        return OrderStatus.cancelled;
      case 'booked':
      default:
        return OrderStatus.booked;
    }
  }

  static ProviderOrderState _providerStateFromStorage(String status) {
    switch (status.trim().toLowerCase()) {
      case 'on_the_way':
        return ProviderOrderState.onTheWay;
      case 'started':
        return ProviderOrderState.started;
      case 'completed':
        return ProviderOrderState.completed;
      case 'declined':
        return ProviderOrderState.declined;
      case 'booked':
      default:
        return ProviderOrderState.incoming;
    }
  }

  static PaymentMethod _paymentMethodFromStorage(String value) {
    switch (value.trim().toLowerCase()) {
      case 'bank_account':
      case 'bank account':
        return PaymentMethod.bankAccount;
      case 'cash':
        return PaymentMethod.cash;
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
