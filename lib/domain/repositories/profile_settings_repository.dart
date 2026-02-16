import '../entities/order.dart';
import '../entities/profile_settings.dart';

abstract class ProfileSettingsRepository {
  void setBearerToken(String token);
  Future<void> initUserRole({required bool isProvider});
  Future<bool> hasRoleProfile({required bool isProvider});

  Future<ProfileFormData> loadProfile({required bool isProvider});
  Future<ProfileFormData> loadProfileFromBackend({required bool isProvider});
  Future<void> saveProfile({
    required bool isProvider,
    required ProfileFormData profile,
  });
  Future<ProviderProfessionData> loadProviderProfession();
  Future<ProviderProfessionData> loadProviderProfessionFromBackend();
  Future<void> saveProviderProfession(ProviderProfessionData profession);

  Future<PaymentMethod> loadPaymentMethod({required bool isProvider});
  Future<void> savePaymentMethod({
    required bool isProvider,
    required PaymentMethod method,
  });

  Future<NotificationPreference> loadNotifications({required bool isProvider});
  Future<void> saveNotifications({
    required bool isProvider,
    required NotificationPreference notification,
  });

  Future<List<HelpSupportTicket>> loadHelpTickets({required bool isProvider});
  Future<void> addHelpTicket({
    required bool isProvider,
    required HelpSupportTicket ticket,
  });
}
