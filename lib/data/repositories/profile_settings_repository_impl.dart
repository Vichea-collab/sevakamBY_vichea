import '../../domain/entities/order.dart';
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
  Future<List<HelpSupportTicket>> loadHelpTickets({required bool isProvider}) {
    return _loadHelpTicketsInternal(isProvider: isProvider);
  }

  @override
  Future<void> addHelpTicket({
    required bool isProvider,
    required HelpSupportTicket ticket,
  }) {
    return _addHelpTicketInternal(isProvider: isProvider, ticket: ticket);
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

  Future<List<HelpSupportTicket>> _loadHelpTicketsInternal({
    required bool isProvider,
  }) async {
    final local = await _localDataSource.loadHelpTickets(
      isProvider: isProvider,
    );
    try {
      final rows = await _remoteDataSource.fetchHelpTickets();
      final remote = rows.map(HelpSupportTicket.fromMap).toList();
      if (remote.isNotEmpty) {
        await _localDataSource.saveHelpTickets(
          isProvider: isProvider,
          tickets: remote,
        );
      }
      return remote.isEmpty ? local : remote;
    } catch (_) {
      return local;
    }
  }

  Future<void> _addHelpTicketInternal({
    required bool isProvider,
    required HelpSupportTicket ticket,
  }) async {
    await _localDataSource.addHelpTicket(
      isProvider: isProvider,
      ticket: ticket,
    );
    try {
      await _remoteDataSource.createHelpTicket(
        title: ticket.title,
        message: ticket.message,
      );
    } catch (_) {}
  }
}
