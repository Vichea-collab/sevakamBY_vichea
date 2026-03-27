import '../entities/pagination.dart';
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
  Future<int> loadProviderCompletedOrdersFromBackend();
  Future<bool> loadProviderVerifiedFromBackend();
  Future<String> loadProviderKycStatusFromBackend();
  Future<void> submitProviderVerification({
    required String idFrontUrl,
    required String idBackUrl,
  });
  Future<void> saveProviderProfession(ProviderProfessionData profession);

  Future<NotificationPreference> loadNotifications({required bool isProvider});
  Future<void> saveNotifications({
    required bool isProvider,
    required NotificationPreference notification,
  });

  Future<PaginatedResult<HelpSupportTicket>> loadHelpTickets({
    required bool isProvider,
    int page = 1,
    int limit = 10,
  });
  Future<HelpSupportTicket> addHelpTicket({
    required bool isProvider,
    required HelpSupportTicket ticket,
  });
  Future<PaginatedResult<HelpTicketMessage>> loadHelpTicketMessages({
    required bool isProvider,
    required String ticketId,
    int page = 1,
    int limit = 10,
  });
  Future<HelpTicketMessage> sendHelpTicketMessage({
    required bool isProvider,
    required String ticketId,
    required String text,
    String? imageUrl,
  });
}
