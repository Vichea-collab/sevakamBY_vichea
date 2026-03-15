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
    await _remoteDataSource.initUserRole(isProvider: isProvider);
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
  Future<bool> loadProviderVerifiedFromBackend() async {
    try {
      return await _remoteDataSource.fetchProviderVerified();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> submitProviderVerification({
    required String idFrontUrl,
    required String idBackUrl,
  }) async {
    await _remoteDataSource.submitProviderVerification(
      idFrontUrl: idFrontUrl,
      idBackUrl: idBackUrl,
    );
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
      items: _sortHelpTicketMessages(
        result.items.map(HelpTicketMessage.fromMap).toList(growable: false),
      ),
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
      await _remoteDataSource.updateSettings(
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
      final remote = _sortHelpTickets(
        result.items.map(HelpSupportTicket.fromMap).toList(),
      );
      if (remote.isNotEmpty && page == 1) {
        await _localDataSource.saveHelpTickets(
          isProvider: isProvider,
          tickets: remote,
        );
      }
      return PaginatedResult(
        items: remote.isEmpty ? _sortHelpTickets(local) : remote,
        pagination: result.pagination,
      );
    } catch (_) {
      final sortedLocal = _sortHelpTickets(local);
      final totalItems = sortedLocal.length;
      final totalPages = totalItems == 0
          ? 0
          : ((totalItems + limit - 1) ~/ limit);
      final start = ((page < 1 ? 1 : page) - 1) * limit;
      final pageItems = start >= totalItems
          ? const <HelpSupportTicket>[]
          : sortedLocal.skip(start).take(limit).toList(growable: false);
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

  List<HelpSupportTicket> _sortHelpTickets(List<HelpSupportTicket> source) {
    final sorted = List<HelpSupportTicket>.from(source);
    sorted.sort((a, b) {
      final right = b.lastMessageAt ?? b.updatedAt ?? b.createdAt;
      final left = a.lastMessageAt ?? a.updatedAt ?? a.createdAt;
      final byTime = right.compareTo(left);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }

  List<HelpTicketMessage> _sortHelpTicketMessages(
    List<HelpTicketMessage> source,
  ) {
    final sorted = List<HelpTicketMessage>.from(source);
    sorted.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return sorted;
  }
}
