import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../domain/entities/order.dart';
import '../../../domain/entities/profile_settings.dart';

class ProfileSettingsLocalDataSource {
  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  String _profileKey(bool isProvider) =>
      'profile.form.${isProvider ? 'provider' : 'finder'}';
  String _paymentKey(bool isProvider) =>
      'profile.payment.${isProvider ? 'provider' : 'finder'}';
  String _notificationKey(bool isProvider) =>
      'profile.notification.${isProvider ? 'provider' : 'finder'}';
  String _helpKey(bool isProvider) =>
      'profile.help.${isProvider ? 'provider' : 'finder'}';
  String _professionKey() => 'profile.profession.provider';

  Future<ProfileFormData> loadProfile({required bool isProvider}) async {
    final raw = (await _prefs).getString(_profileKey(isProvider));
    if (raw == null || raw.isEmpty) {
      return isProvider
          ? ProfileFormData.providerDefault()
          : ProfileFormData.finderDefault();
    }
    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic>) {
      return isProvider
          ? ProfileFormData.providerDefault()
          : ProfileFormData.finderDefault();
    }
    return ProfileFormData.fromMap(map);
  }

  Future<void> saveProfile({
    required bool isProvider,
    required ProfileFormData profile,
  }) async {
    await (await _prefs).setString(
      _profileKey(isProvider),
      jsonEncode(profile.toMap()),
    );
  }

  Future<ProviderProfessionData> loadProviderProfession() async {
    final raw = (await _prefs).getString(_professionKey());
    if (raw == null || raw.isEmpty) return ProviderProfessionData.defaults();
    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic>) return ProviderProfessionData.defaults();
    return ProviderProfessionData.fromMap(map);
  }

  Future<void> saveProviderProfession({
    required ProviderProfessionData profession,
  }) async {
    await (await _prefs).setString(
      _professionKey(),
      jsonEncode(profession.toMap()),
    );
  }

  Future<PaymentMethod> loadPaymentMethod({required bool isProvider}) async {
    final value = (await _prefs).getString(_paymentKey(isProvider));
    if (value == null || value.isEmpty) return PaymentMethod.creditCard;
    return paymentMethodFromStorageValue(value);
  }

  Future<void> savePaymentMethod({
    required bool isProvider,
    required PaymentMethod method,
  }) async {
    await (await _prefs).setString(
      _paymentKey(isProvider),
      paymentMethodToStorageValue(method),
    );
  }

  Future<NotificationPreference> loadNotifications({
    required bool isProvider,
  }) async {
    final raw = (await _prefs).getString(_notificationKey(isProvider));
    if (raw == null || raw.isEmpty) return NotificationPreference.defaults();
    final map = jsonDecode(raw);
    if (map is! Map<String, dynamic>) return NotificationPreference.defaults();
    return NotificationPreference.fromMap(map);
  }

  Future<void> saveNotifications({
    required bool isProvider,
    required NotificationPreference notification,
  }) async {
    await (await _prefs).setString(
      _notificationKey(isProvider),
      jsonEncode(notification.toMap()),
    );
  }

  Future<List<HelpSupportTicket>> loadHelpTickets({
    required bool isProvider,
  }) async {
    final raw = (await _prefs).getString(_helpKey(isProvider));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(HelpSupportTicket.fromMap)
        .toList();
  }

  Future<void> addHelpTicket({
    required bool isProvider,
    required HelpSupportTicket ticket,
  }) async {
    final current = await loadHelpTickets(isProvider: isProvider);
    final updated = [ticket, ...current].map((item) => item.toMap()).toList();
    await (await _prefs).setString(_helpKey(isProvider), jsonEncode(updated));
  }

  Future<void> saveHelpTickets({
    required bool isProvider,
    required List<HelpSupportTicket> tickets,
  }) async {
    final payload = tickets.map((item) => item.toMap()).toList();
    await (await _prefs).setString(_helpKey(isProvider), jsonEncode(payload));
  }
}
