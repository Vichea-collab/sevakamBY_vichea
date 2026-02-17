import '../../domain/entities/order.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/repositories/profile_settings_repository.dart';
import '../datasources/local/profile_settings_local_data_source.dart';
import '../datasources/remote/profile_remote_data_source.dart';

class ProfileSettingsRepositoryImpl implements ProfileSettingsRepository {
  final ProfileSettingsLocalDataSource _localDataSource;
  final ProfileRemoteDataSource _remoteDataSource;

  const ProfileSettingsRepositoryImpl({
    required ProfileSettingsLocalDataSource localDataSource,
    required ProfileRemoteDataSource remoteDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  @override
  void setBearerToken(String token) {
    _remoteDataSource.setBearerToken(token);
  }

  @override
  Future<void> initUserRole({required bool isProvider}) async {
    try {
      await _remoteDataSource.initUserRole(isProvider: isProvider);
    } catch (_) {
      // Keep local experience available even when backend role init is unavailable.
    }
  }

  @override
  Future<bool> hasRoleProfile({required bool isProvider}) {
    return _remoteDataSource.hasRoleProfile(isProvider: isProvider);
  }

  @override
  Future<ProfileFormData> loadProfile({required bool isProvider}) {
    return _localDataSource.loadProfile(isProvider: isProvider);
  }

  @override
  Future<ProviderProfessionData> loadProviderProfession() {
    return _localDataSource.loadProviderProfession();
  }

  @override
  Future<ProfileFormData> loadProfileFromBackend({
    required bool isProvider,
  }) async {
    final remote = await _remoteDataSource.fetchProfile(isProvider: isProvider);
    await saveProfile(isProvider: isProvider, profile: remote);
    return remote;
  }

  @override
  Future<void> saveProfile({
    required bool isProvider,
    required ProfileFormData profile,
  }) {
    return _saveProfileInternal(isProvider: isProvider, profile: profile);
  }

  @override
  Future<ProviderProfessionData> loadProviderProfessionFromBackend() async {
    final local = await _localDataSource.loadProviderProfession();
    try {
      final remote = await _remoteDataSource.fetchProviderProfession();
      await _localDataSource.saveProviderProfession(profession: remote);
      return remote;
    } catch (_) {
      return local;
    }
  }

  @override
  Future<int> loadProviderCompletedOrdersFromBackend() async {
    try {
      return await _remoteDataSource.fetchProviderCompletedOrders();
    } catch (_) {
      return 0;
    }
  }

  @override
  Future<void> saveProviderProfession(ProviderProfessionData profession) async {
    await _localDataSource.saveProviderProfession(profession: profession);
    try {
      final remote = await _remoteDataSource.updateProviderProfession(
        profession: profession,
      );
      await _localDataSource.saveProviderProfession(profession: remote);
    } catch (_) {}
  }

  @override
  Future<PaymentMethod> loadPaymentMethod({required bool isProvider}) {
    return _loadPaymentMethodInternal(isProvider: isProvider);
  }

  @override
  Future<void> savePaymentMethod({
    required bool isProvider,
    required PaymentMethod method,
  }) {
    return _savePaymentMethodInternal(isProvider: isProvider, method: method);
  }

  @override
  Future<NotificationPreference> loadNotifications({required bool isProvider}) {
    return _loadNotificationsInternal(isProvider: isProvider);
  }

  @override
  Future<void> saveNotifications({
    required bool isProvider,
    required NotificationPreference notification,
  }) {
    return _saveNotificationsInternal(
      isProvider: isProvider,
      notification: notification,
    );
  }

  @override
  Future<PaginatedResult<HelpSupportTicket>> loadHelpTickets({
    required bool isProvider,
    int page = 1,
    int limit = 10,
  }) {
    return _loadHelpTicketsInternal(
      isProvider: isProvider,
      page: page,
      limit: limit,
    );
  }

  @override
  Future<HelpSupportTicket> addHelpTicket({
    required bool isProvider,
    required HelpSupportTicket ticket,
  }) {
    return _addHelpTicketInternal(isProvider: isProvider, ticket: ticket);
  }

  @override
  Future<PaginatedResult<HelpTicketMessage>> loadHelpTicketMessages({
    required bool isProvider,
    required String ticketId,
    int page = 1,
    int limit = 10,
  }) async {
    final result = await _remoteDataSource.fetchHelpTicketMessages(
      ticketId: ticketId,
      page: page,
      limit: limit,
    );
    return PaginatedResult(
      items: result.items
          .map(HelpTicketMessage.fromMap)
          .toList(growable: false),
      pagination: result.pagination,
    );
  }

  @override
  Future<HelpTicketMessage> sendHelpTicketMessage({
    required bool isProvider,
    required String ticketId,
    required String text,
  }) async {
    final message = await _remoteDataSource.sendHelpTicketMessage(
      ticketId: ticketId,
      text: text,
    );
    return HelpTicketMessage.fromMap(message);
  }

  Future<void> _saveProfileInternal({
    required bool isProvider,
    required ProfileFormData profile,
  }) async {
    await _localDataSource.saveProfile(
      isProvider: isProvider,
      profile: profile,
    );
    try {
      final remote = await _remoteDataSource.updateProfile(
        isProvider: isProvider,
        profile: profile,
      );
      await _localDataSource.saveProfile(
        isProvider: isProvider,
        profile: remote,
      );
    } catch (_) {}
  }

  Future<PaymentMethod> _loadPaymentMethodInternal({
    required bool isProvider,
  }) async {
    final local = await _localDataSource.loadPaymentMethod(
      isProvider: isProvider,
    );
    try {
      final data = await _remoteDataSource.fetchSettings();
      final value = (data['paymentMethod'] ?? '').toString();
      if (value.isEmpty) return local;
      final parsed = paymentMethodFromStorageValue(value);
      await _localDataSource.savePaymentMethod(
        isProvider: isProvider,
        method: parsed,
      );
      return parsed;
    } catch (_) {
      return local;
    }
  }

  Future<void> _savePaymentMethodInternal({
    required bool isProvider,
    required PaymentMethod method,
  }) async {
    await _localDataSource.savePaymentMethod(
      isProvider: isProvider,
      method: method,
    );
    try {
      final notification = await _localDataSource.loadNotifications(
        isProvider: isProvider,
      );
      await _remoteDataSource.updateSettings(
        paymentMethod: paymentMethodToStorageValue(method),
        notifications: notification.toMap(),
      );
    } catch (_) {}
  }

  Future<NotificationPreference> _loadNotificationsInternal({
    required bool isProvider,
  }) async {
    final local = await _localDataSource.loadNotifications(
      isProvider: isProvider,
    );
    try {
      final data = await _remoteDataSource.fetchSettings();
      final raw = data['notifications'];
      if (raw is! Map) return local;
      final parsed = NotificationPreference.fromMap(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
      await _localDataSource.saveNotifications(
        isProvider: isProvider,
        notification: parsed,
      );
      return parsed;
    } catch (_) {
      return local;
    }
  }

  Future<void> _saveNotificationsInternal({
    required bool isProvider,
    required NotificationPreference notification,
  }) async {
    await _localDataSource.saveNotifications(
      isProvider: isProvider,
      notification: notification,
    );
    try {
      final payment = await _localDataSource.loadPaymentMethod(
        isProvider: isProvider,
      );
      await _remoteDataSource.updateSettings(
        paymentMethod: paymentMethodToStorageValue(payment),
        notifications: notification.toMap(),
      );
    } catch (_) {}
  }

  Future<PaginatedResult<HelpSupportTicket>> _loadHelpTicketsInternal({
    required bool isProvider,
    required int page,
    required int limit,
  }) async {
    final local = await _localDataSource.loadHelpTickets(
      isProvider: isProvider,
    );
    try {
      final result = await _remoteDataSource.fetchHelpTickets(
        page: page,
        limit: limit,
      );
      final remote = result.items.map(HelpSupportTicket.fromMap).toList();
      if (remote.isNotEmpty && page == 1) {
        await _localDataSource.saveHelpTickets(
          isProvider: isProvider,
          tickets: remote,
        );
      }
      return PaginatedResult(
        items: remote.isEmpty ? local : remote,
        pagination: result.pagination,
      );
    } catch (_) {
      final totalItems = local.length;
      final totalPages = totalItems == 0
          ? 0
          : ((totalItems + limit - 1) ~/ limit);
      final start = ((page < 1 ? 1 : page) - 1) * limit;
      final pageItems = start >= totalItems
          ? const <HelpSupportTicket>[]
          : local.skip(start).take(limit).toList(growable: false);
      return PaginatedResult(
        items: pageItems,
        pagination: PaginationMeta(
          page: page,
          limit: limit,
          totalItems: totalItems,
          totalPages: totalPages,
          hasPrevPage: totalPages > 0 && page > 1,
          hasNextPage: totalPages > 0 && page < totalPages,
        ),
      );
    }
  }

  Future<HelpSupportTicket> _addHelpTicketInternal({
    required bool isProvider,
    required HelpSupportTicket ticket,
  }) async {
    final localTicket = ticket.id.isEmpty
        ? HelpSupportTicket(
            id: 'local-${ticket.createdAt.microsecondsSinceEpoch}',
            title: ticket.title,
            message: ticket.message,
            status: ticket.status,
            createdAt: ticket.createdAt,
            updatedAt: ticket.updatedAt,
            lastMessageText: ticket.lastMessageText,
            lastMessageAt: ticket.lastMessageAt,
          )
        : ticket;
    await _localDataSource.addHelpTicket(
      isProvider: isProvider,
      ticket: localTicket,
    );
    try {
      final created = await _remoteDataSource.createHelpTicket(
        title: ticket.title,
        message: ticket.message,
      );
      return HelpSupportTicket.fromMap(created);
    } catch (_) {}
    return localTicket;
  }
}
