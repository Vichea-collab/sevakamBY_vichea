import 'package:flutter/foundation.dart';

import '../../core/config/app_env.dart';
import '../../data/datasources/local/profile_settings_local_data_source.dart';
import '../../data/datasources/remote/profile_remote_data_source.dart';
import '../../data/network/backend_api_client.dart';
import '../../data/repositories/profile_settings_repository_impl.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/profile_settings.dart';
import '../../domain/repositories/profile_settings_repository.dart';
import 'app_role_state.dart';

class ProfileSettingsState {
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
    finderHelpTickets.value = await _repository.loadHelpTickets(
      isProvider: false,
    );
    providerHelpTickets.value = await _repository.loadHelpTickets(
      isProvider: true,
    );
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
      } else {
        finderProfile.value = profile;
      }
      return true;
    } catch (_) {
      return false;
    }
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
      providerHelpTickets.value = updated;
    } else {
      finderHelpTickets.value = updated;
    }
  }
}
