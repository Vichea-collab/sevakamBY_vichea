import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../data/datasources/local/profile_settings_local_data_source.dart';
import '../../data/datasources/remote/profile_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/profile_settings_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/pagination.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/repositories/profile_settings_repository.dart';
import 'app_role_state.dart';

class ProfileSettingsState {
  static const int _helpPageSize = 10;

  static final ProfileSettingsRepository _repository =
      ProfileSettingsRepositoryImpl(
        localDataSource: ProfileSettingsLocalDataSource(),
        remoteDataSource: ProfileRemoteDataSource(
          BackendApiClient(
            baseUrl: AppEnv.apiBaseUrl(),
            bearerToken: AppEnv.apiAuthToken(),
          ),
        ),
      );

  static final ValueNotifier<ProfileFormData> finderProfile = ValueNotifier(
    ProfileFormData.finderDefault(),
  );
  static final ValueNotifier<ProfileFormData> providerProfile = ValueNotifier(
    ProfileFormData.providerDefault(),
  );
  static final ValueNotifier<ProviderProfessionData> providerProfession =
      ValueNotifier(ProviderProfessionData.defaults());
  static final ValueNotifier<int> providerCompletedOrders = ValueNotifier(0);

  static final ValueNotifier<PaymentMethod> finderPaymentMethod = ValueNotifier(
    PaymentMethod.creditCard,
  );
  static final ValueNotifier<PaymentMethod> providerPaymentMethod =
      ValueNotifier(PaymentMethod.creditCard);

  static final ValueNotifier<NotificationPreference> finderNotification =
      ValueNotifier(NotificationPreference.defaults());
  static final ValueNotifier<NotificationPreference> providerNotification =
      ValueNotifier(NotificationPreference.defaults());

  static final ValueNotifier<List<HelpSupportTicket>> finderHelpTickets =
      ValueNotifier(const <HelpSupportTicket>[]);
  static final ValueNotifier<List<HelpSupportTicket>> providerHelpTickets =
      ValueNotifier(const <HelpSupportTicket>[]);
  static final ValueNotifier<PaginationMeta> finderHelpTicketsPagination =
      ValueNotifier(const PaginationMeta.initial(limit: _helpPageSize));
  static final ValueNotifier<PaginationMeta> providerHelpTicketsPagination =
      ValueNotifier(const PaginationMeta.initial(limit: _helpPageSize));

  static bool _initialized = false;

  static bool get isProvider => AppRoleState.isProvider;

  static ValueListenable<ProfileFormData> get currentProfileListenable =>
      isProvider ? providerProfile : finderProfile;

  static ProfileFormData get currentProfile =>
      isProvider ? providerProfile.value : finderProfile.value;

  static PaymentMethod get currentPaymentMethod =>
      isProvider ? providerPaymentMethod.value : finderPaymentMethod.value;

  static NotificationPreference get currentNotification =>
      isProvider ? providerNotification.value : finderNotification.value;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    finderProfile.value = await _repository.loadProfile(isProvider: false);
    providerProfile.value = await _repository.loadProfile(isProvider: true);
    finderPaymentMethod.value = await _repository.loadPaymentMethod(
      isProvider: false,
    );
    providerPaymentMethod.value = await _repository.loadPaymentMethod(
      isProvider: true,
    );
    finderNotification.value = await _repository.loadNotifications(
      isProvider: false,
    );
    providerNotification.value = await _repository.loadNotifications(
      isProvider: true,
    );
    final finderTicketsResult = await _repository.loadHelpTickets(
      isProvider: false,
    );
    finderHelpTickets.value = finderTicketsResult.items;
    finderHelpTicketsPagination.value = finderTicketsResult.pagination;
    final providerTicketsResult = await _repository.loadHelpTickets(
      isProvider: true,
    );
    providerHelpTickets.value = providerTicketsResult.items;
    providerHelpTicketsPagination.value = providerTicketsResult.pagination;
    providerProfession.value = await _repository.loadProviderProfession();
    providerCompletedOrders.value = await _repository
        .loadProviderCompletedOrdersFromBackend();
  }

  static void setBackendToken(String token) {
    _repository.setBearerToken(token);
  }

  static Future<void> initUserRoleOnBackend({required bool isProvider}) {
    return _repository.initUserRole(isProvider: isProvider);
  }

  static Future<bool> hasRoleRegisteredOnBackend({
    required bool isProvider,
  }) async {
    try {
      return await _repository.hasRoleProfile(isProvider: isProvider);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> syncRoleProfileFromBackend({
    required bool isProvider,
  }) async {
    try {
      final profile = await _repository.loadProfileFromBackend(
        isProvider: isProvider,
      );
      if (isProvider) {
        providerProfile.value = profile;
        providerProfession.value = await _repository
            .loadProviderProfessionFromBackend();
        providerCompletedOrders.value = await _repository
            .loadProviderCompletedOrdersFromBackend();
      } else {
        finderProfile.value = profile;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> syncProviderProfessionFromBackend() async {
    try {
      providerProfession.value = await _repository
          .loadProviderProfessionFromBackend();
      providerCompletedOrders.value = await _repository
          .loadProviderCompletedOrdersFromBackend();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> syncProviderCompletedOrdersFromBackend() async {
    try {
      providerCompletedOrders.value = await _repository
          .loadProviderCompletedOrdersFromBackend();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> saveProviderProfession(
    ProviderProfessionData value,
  ) async {
    await _repository.saveProviderProfession(value);
    providerProfession.value = value;
  }

  static Future<void> saveCurrentProfile(ProfileFormData profile) async {
    await _repository.saveProfile(isProvider: isProvider, profile: profile);
    if (isProvider) {
      providerProfile.value = profile;
    } else {
      finderProfile.value = profile;
    }
  }

  static Future<void> saveCurrentPaymentMethod(PaymentMethod method) async {
    await _repository.savePaymentMethod(isProvider: isProvider, method: method);
    if (isProvider) {
      providerPaymentMethod.value = method;
    } else {
      finderPaymentMethod.value = method;
    }
  }

  static Future<void> saveCurrentNotifications(
    NotificationPreference value,
  ) async {
    await _repository.saveNotifications(
      isProvider: isProvider,
      notification: value,
    );
    if (isProvider) {
      providerNotification.value = value;
    } else {
      finderNotification.value = value;
    }
  }

  static Future<void> addCurrentHelpTicket(HelpSupportTicket ticket) async {
    await _repository.addHelpTicket(isProvider: isProvider, ticket: ticket);
    final current = isProvider
        ? providerHelpTickets.value
        : finderHelpTickets.value;
    final updated = [ticket, ...current];
    if (isProvider) {
      providerHelpTickets.value = updated.take(_helpPageSize).toList();
      providerHelpTicketsPagination.value = _withAdjustedTotalItems(
        providerHelpTicketsPagination.value,
        delta: 1,
      );
    } else {
      finderHelpTickets.value = updated.take(_helpPageSize).toList();
      finderHelpTicketsPagination.value = _withAdjustedTotalItems(
        finderHelpTicketsPagination.value,
        delta: 1,
      );
    }
  }

  static Future<void> refreshCurrentHelpTickets({int page = 1}) async {
    final result = await _repository.loadHelpTickets(
      isProvider: isProvider,
      page: page,
      limit: _helpPageSize,
    );
    if (isProvider) {
      providerHelpTickets.value = result.items;
      providerHelpTicketsPagination.value = result.pagination;
    } else {
      finderHelpTickets.value = result.items;
      finderHelpTicketsPagination.value = result.pagination;
    }
  }

  static PaginationMeta _withAdjustedTotalItems(
    PaginationMeta current, {
    required int delta,
  }) {
    final totalItems = (current.totalItems + delta).clamp(0, 99999999);
    final limit = current.limit <= 0 ? _helpPageSize : current.limit;
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
}
