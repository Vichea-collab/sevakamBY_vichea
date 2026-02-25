import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../domain/entities/profile_settings.dart';
import 'app_sync_state.dart';
import 'app_role_state.dart';
import 'chat_state.dart';
import 'finder_post_state.dart';
import 'order_state.dart';
import 'profile_image_state.dart';
import 'provider_post_state.dart';
import 'profile_settings_state.dart';
import 'user_notification_state.dart';

class AuthState {
  static final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  static final ValueNotifier<bool> ready = ValueNotifier(false);
  static const Duration _authOperationTimeout = Duration(seconds: 18);

  static bool _initialized = false;
  static bool _googleInitialized = false;
  static StreamSubscription<User?>? _idTokenSubscription;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) {
      ready.value = true;
      return;
    }

    final auth = FirebaseAuth.instance;
    currentUser.value = auth.currentUser;
    if (auth.currentUser != null) {
      await _syncSignedInUser(auth.currentUser!);
    } else {
      await AppSyncState.setSignedIn(false);
    }
    await _idTokenSubscription?.cancel();
    _idTokenSubscription = auth.idTokenChanges().listen(
      (user) async {
        currentUser.value = user;
        if (user == null) {
          _applyBackendTokenToStates('');
          await AppSyncState.setSignedIn(false);
          return;
        }
        await _syncSignedInUser(user);
      },
      onError: (error, stackTrace) {
        debugPrint('AuthState.idTokenChanges error: $error');
      },
    );
    ready.value = true;
  }

  static Future<void> _syncSignedInUser(User user) async {
    String token = '';
    try {
      token = await user.getIdToken() ?? '';
    } catch (error) {
      debugPrint('AuthState.getIdToken failed: $error');
    }
    _applyBackendTokenToStates(token);
    if (token.trim().isEmpty) {
      await AppSyncState.setSignedIn(false);
      return;
    }

    try {
      await _alignRoleToRegisteredProfile();
      final isAdmin = await _isAdminSession(user);
      if (isAdmin) {
        await AppSyncState.setSignedIn(false);
        return;
      }

      await ChatState.refresh();
      await FinderPostState.refresh();
      await FinderPostState.refreshAllForLookup();
      await ProviderPostState.refresh();
      await ProviderPostState.refreshAllForLookup();
      await OrderState.refreshCurrentRole();
      await AppSyncState.setSignedIn(true);
    } catch (error) {
      debugPrint('AuthState._syncSignedInUser failed: $error');
      await AppSyncState.setSignedIn(false);
    }
  }

  static bool get isSignedIn => currentUser.value != null;

  static Future<String?> signInWithGoogle({
    required bool isProvider,
    bool registerIfMissing = true,
  }) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    try {
      final UserCredential result;
      final provider = GoogleAuthProvider()..addScope('email');
      provider.setCustomParameters({'prompt': 'select_account'});
      if (kIsWeb) {
        result = await _runAuthOperation(
          operation: 'Google sign-in',
          action: () => FirebaseAuth.instance.signInWithPopup(provider),
        );
      } else {
        await _ensureGoogleInitialized();
        final account = await _runAuthOperation(
          operation: 'Google account selection',
          action: GoogleSignIn.instance.authenticate,
          enforceTimeout: false,
        );
        final authentication = account.authentication;
        final idToken = authentication.idToken?.trim() ?? '';
        if (idToken.isEmpty) {
          return 'Google sign-in token is missing. Check Firebase Google provider and Android OAuth SHA setup.';
        }
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        result = await _runAuthOperation(
          operation: 'Google sign-in',
          action: () => FirebaseAuth.instance.signInWithCredential(credential),
        );
      }
      final user = result.user;
      if (user == null) return 'Google sign-in failed.';
      final sessionError = await _applyAuthenticatedSession(
        user,
        isProvider: isProvider,
        registerRoleIfMissing: registerIfMissing,
      );
      if (sessionError != null) return sessionError;

      if (registerIfMissing) {
        final fullName = user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : (isProvider ? 'Service Provider' : 'Service Finder');
        final email = user.email?.trim() ?? '';
        await _seedProfileAfterRegistration(
          isProvider: isProvider,
          fullName: fullName,
          email: email,
        );
        ProfileImageState.useDefaultAvatar(isProvider: isProvider);
      } else {
        await ProfileSettingsState.syncRoleProfileFromBackend(
          isProvider: isProvider,
        );
      }
      return null;
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'FirebaseAuthException (google credential): code=${error.code}, message=${error.message}',
      );
      return _friendlyAuthError(error, googleFlow: true);
    } on GoogleSignInException catch (error) {
      debugPrint(
        'GoogleSignInException: code=${error.code}, desc=${error.description}, details=${error.details}',
      );
      return _friendlyGoogleSignInError(error);
    } catch (error) {
      debugPrint('Google sign-in unexpected error: $error');
      return _friendlyUnknownGoogleError(error);
    }
  }

  static Future<String?> signInWithEmailPassword({
    required bool isProvider,
    required String email,
    required String password,
  }) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    try {
      final result = await _runAuthOperation(
        operation: 'Email sign-in',
        action: () => FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        ),
      );
      final user = result.user;
      if (user == null) return 'Sign-in failed.';
      final sessionError = await _applyAuthenticatedSession(
        user,
        isProvider: isProvider,
        registerRoleIfMissing: false,
      );
      if (sessionError != null) return sessionError;
      await ProfileSettingsState.syncRoleProfileFromBackend(
        isProvider: isProvider,
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return _friendlyUnknownAuthError(error);
    }
  }

  static Future<String?> sendPasswordResetEmail({required String email}) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Email is required.';

    try {
      await _runAuthOperation(
        operation: 'Password reset',
        action: () =>
            FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed),
      );
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return _friendlyUnknownAuthError(error);
    }
  }

  static Future<String?> signUpWithEmailPassword({
    required bool isProvider,
    required String fullName,
    required String email,
    required String password,
    String phoneNumber = '',
    String city = '',
    String country = '',
    String dateOfBirth = '',
    String bio = '',
  }) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    try {
      User? user;
      try {
        final result = await _runAuthOperation(
          operation: 'Account registration',
          action: () => FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ),
        );
        user = result.user;
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        final existing = await _runAuthOperation(
          operation: 'Existing account sign-in',
          action: () => FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ),
        );
        user = existing.user;
      }

      if (user == null) return 'Sign-up failed.';
      if (fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }
      final sessionError = await _applyAuthenticatedSession(
        user,
        isProvider: isProvider,
        registerRoleIfMissing: true,
      );
      if (sessionError != null) return sessionError;
      await _seedProfileAfterRegistration(
        isProvider: isProvider,
        fullName: fullName.trim(),
        email: email.trim(),
        phoneNumber: phoneNumber.trim(),
        city: city.trim(),
        country: country.trim(),
        dateOfBirth: dateOfBirth.trim(),
        bio: bio.trim(),
      );
      ProfileImageState.useDefaultAvatar(isProvider: isProvider);
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return _friendlyUnknownAuthError(error);
    }
  }

  static Future<void> signOut() async {
    if (!FirebaseBootstrap.isConfigured) return;
    await FirebaseAuth.instance.signOut();
    try {
      if (!kIsWeb) {
        await _ensureGoogleInitialized();
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    _applyBackendTokenToStates('');
    await AppSyncState.setSignedIn(false);
  }

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final webClientId = AppEnv.firebaseWebClientId().trim();
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );
    _googleInitialized = true;
  }

  static Future<String?> switchRole({required bool toProvider}) async {
    final user = currentUser.value;
    if (user == null) {
      return 'Please sign in first.';
    }
    final token = await user.getIdToken(true);
    _applyBackendTokenToStates(token ?? '');
    final hasRole = await ProfileSettingsState.hasRoleRegisteredOnBackend(
      isProvider: toProvider,
    );
    if (!hasRole) {
      return _missingRoleMessage(toProvider);
    }

    AppRoleState.setProvider(toProvider);
    await ChatState.refresh();
    await ProfileSettingsState.syncRoleProfileFromBackend(
      isProvider: toProvider,
    );
    await FinderPostState.refresh();
    await FinderPostState.refreshAllForLookup();
    await ProviderPostState.refresh();
    await ProviderPostState.refreshAllForLookup();
    await OrderState.refreshCurrentRole();
    return null;
  }

  static Future<String?> _applyAuthenticatedSession(
    User user, {
    required bool isProvider,
    required bool registerRoleIfMissing,
  }) async {
    final token = await user.getIdToken(true);
    _applyBackendTokenToStates(token ?? '');
    if (registerRoleIfMissing) {
      await ProfileSettingsState.initUserRoleOnBackend(isProvider: isProvider);
    }
    final hasRole = await ProfileSettingsState.hasRoleRegisteredOnBackend(
      isProvider: isProvider,
    );
    if (!hasRole) {
      return _missingRoleMessage(isProvider);
    }
    AppRoleState.setProvider(isProvider);
    await ChatState.refresh();
    await FinderPostState.refresh();
    await FinderPostState.refreshAllForLookup();
    await ProviderPostState.refresh();
    await ProviderPostState.refreshAllForLookup();
    await OrderState.refreshCurrentRole();
    return null;
  }

  static Future<void> _seedProfileAfterRegistration({
    required bool isProvider,
    required String fullName,
    required String email,
    String phoneNumber = '',
    String city = '',
    String country = '',
    String dateOfBirth = '',
    String bio = '',
  }) async {
    final base = isProvider
        ? ProfileFormData.providerDefault()
        : ProfileFormData.finderDefault();
    final seeded = base.copyWith(
      name: fullName.isEmpty ? base.name : fullName,
      email: email.isEmpty ? base.email : email,
      phoneNumber: phoneNumber.isEmpty ? base.phoneNumber : phoneNumber,
      city: city.isEmpty ? base.city : city,
      country: country.isEmpty ? base.country : country,
      dateOfBirth: dateOfBirth.isEmpty ? base.dateOfBirth : dateOfBirth,
      bio: bio.isEmpty ? base.bio : bio,
    );
    await ProfileSettingsState.saveCurrentProfile(seeded);
    await ProfileSettingsState.syncRoleProfileFromBackend(
      isProvider: isProvider,
    );
  }

  static Future<void> _alignRoleToRegisteredProfile() async {
    final currentIsProvider = AppRoleState.isProvider;
    final hasCurrentRole =
        await ProfileSettingsState.hasRoleRegisteredOnBackend(
          isProvider: currentIsProvider,
        );
    if (hasCurrentRole) return;

    final fallbackIsProvider = !currentIsProvider;
    final hasFallbackRole =
        await ProfileSettingsState.hasRoleRegisteredOnBackend(
          isProvider: fallbackIsProvider,
        );
    if (hasFallbackRole) {
      AppRoleState.setProvider(fallbackIsProvider);
    }
  }

  static void _applyBackendTokenToStates(String token) {
    ProfileSettingsState.setBackendToken(token);
    ChatState.setBackendToken(token);
    FinderPostState.setBackendToken(token);
    ProviderPostState.setBackendToken(token);
    OrderState.setBackendToken(token);
    UserNotificationState.setBackendToken(token);
  }

  static Future<bool> _isAdminSession(User user) async {
    try {
      final token = await user.getIdTokenResult();
      final claims = token.claims ?? const <String, dynamic>{};
      final role = (claims['role'] ?? '').toString().trim().toLowerCase();
      if (role == 'admin' || role == 'admins') return true;
      final rolesRaw = claims['roles'];
      if (rolesRaw is List) {
        final normalized = rolesRaw
            .map((value) => value.toString().trim().toLowerCase())
            .toSet();
        if (normalized.contains('admin') || normalized.contains('admins')) {
          return true;
        }
      }
    } catch (_) {}
    final email = (user.email ?? '').trim().toLowerCase();
    return email == 'admin@gmail.com';
  }

  static String _missingRoleMessage(bool isProvider) {
    if (isProvider) {
      return 'Provider account is not registered for this email. Please register provider role first.';
    }
    return 'Finder account is not registered for this email. Please register finder role first.';
  }

  static String _friendlyAuthError(
    FirebaseAuthException error, {
    bool googleFlow = false,
  }) {
    final message = (error.message ?? '').toLowerCase();
    final looksNetworkIssue =
        message.contains('network') ||
        message.contains('timeout') ||
        message.contains('failed to resolve name') ||
        message.contains('unable to resolve host') ||
        message.contains('unknown host') ||
        message.contains('connection');

    if (googleFlow) {
      if (looksNetworkIssue) {
        return _networkAuthHint();
      }
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'This email is linked to another sign-in method. Sign in with that method first, then link Google from account settings.';
        case 'invalid-credential':
          return 'Google sign-in credential is invalid. Check Firebase OAuth setup (package name, SHA keys, and google-services.json).';
        case 'operation-not-allowed':
          return 'Google sign-in is disabled in Firebase Authentication. Enable Google provider and try again.';
        case 'popup-closed-by-user':
        case 'cancelled-popup-request':
        case 'web-context-cancelled':
        case 'user-cancelled':
          return 'Google sign-in was canceled or interrupted. If this keeps happening, check emulator internet/DNS and retry.';
        case 'user-disabled':
          return 'This account has been disabled.';
      }
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return _networkAuthHint();
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Authentication failed.';
    }
  }

  static String _friendlyUnknownGoogleError(Object error) {
    final raw = error.toString().trim();
    final signal = raw.toLowerCase();
    if (signal.contains('apiexception: 10') ||
        signal.contains('developer_error') ||
        signal.contains('google-services.json') ||
        signal.contains('sha-1') ||
        signal.contains('sha1')) {
      return 'Google sign-in is not configured correctly. Check Firebase Android SHA keys and google-services.json.';
    }
    if (signal.contains('network') ||
        signal.contains('timeout') ||
        signal.contains('failed to resolve name') ||
        signal.contains('unable to resolve host')) {
      return _networkAuthHint();
    }
    return raw.isEmpty ? 'Google sign-in failed.' : raw;
  }

  static String _friendlyGoogleSignInError(GoogleSignInException error) {
    final details = error.details?.toString().trim() ?? '';
    final description = error.description?.trim() ?? '';
    final signal = '$description $details'.toLowerCase();
    String withDetails(String message) {
      if (details.isEmpty) return message;
      return '$message ($details)';
    }

    if (signal.contains('network') ||
        signal.contains('failed to resolve name') ||
        signal.contains('unable to resolve host') ||
        signal.contains('unknown host') ||
        signal.contains('timeout')) {
      return withDetails(_networkAuthHint());
    }
    if (signal.contains('apiexception: 10') ||
        signal.contains('developer_error') ||
        signal.contains('sha-1') ||
        signal.contains('sha1') ||
        signal.contains('google-services.json')) {
      return withDetails(
        'Google sign-in is not configured correctly. Check Firebase Android SHA keys and google-services.json.',
      );
    }

    switch (error.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
        return withDetails(
          'Google sign-in is not configured correctly. Check Firebase Android SHA keys and google-services.json.',
        );
      case GoogleSignInExceptionCode.providerConfigurationError:
        return withDetails(
          'Google provider configuration failed. Verify Google sign-in is enabled in Firebase Authentication.',
        );
      case GoogleSignInExceptionCode.canceled:
        return withDetails(
          'Google sign-in was canceled. Please select a Google account and try again.',
        );
      case GoogleSignInExceptionCode.interrupted:
        return withDetails('Google sign-in was interrupted. Please try again.');
      case GoogleSignInExceptionCode.uiUnavailable:
        return withDetails('Google sign-in UI is unavailable on this device.');
      case GoogleSignInExceptionCode.userMismatch:
        return withDetails(
          'Google account mismatch detected. Please sign out and retry.',
        );
      case GoogleSignInExceptionCode.unknownError:
        return withDetails(
          description.isEmpty ? 'Google sign-in failed.' : description,
        );
    }
  }

  static String _friendlyUnknownAuthError(Object error) {
    final raw = error.toString().trim();
    final signal = raw.toLowerCase();
    if (signal.contains('network') ||
        signal.contains('timeout') ||
        signal.contains('failed to resolve name') ||
        signal.contains('unable to resolve host')) {
      return _networkAuthHint();
    }
    return raw.isEmpty ? 'Authentication failed.' : raw;
  }

  static Future<T> _runAuthOperation<T>({
    required String operation,
    required Future<T> Function() action,
    bool enforceTimeout = true,
  }) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 700),
      Duration(milliseconds: 1400),
    ];
    var attempt = 0;
    while (true) {
      try {
        if (!enforceTimeout) {
          return await action();
        }
        return await action().timeout(
          _authOperationTimeout,
          onTimeout: () =>
              throw TimeoutException('$operation timed out. Please try again.'),
        );
      } catch (error) {
        final shouldRetry =
            _isTransientAuthNetworkError(error) && attempt < retryDelays.length;
        if (!shouldRetry) rethrow;
        await Future.delayed(retryDelays[attempt]);
        attempt += 1;
      }
    }
  }

  static bool _isTransientAuthNetworkError(Object error) {
    if (error is TimeoutException) return true;
    if (error is FirebaseAuthException &&
        error.code == 'network-request-failed') {
      return true;
    }
    final text = error.toString().toLowerCase();
    return text.contains('network error') ||
        text.contains('failed to resolve name') ||
        text.contains('unable to resolve host') ||
        text.contains('connection reset') ||
        text.contains('connection refused') ||
        text.contains('socket') ||
        text.contains('timed out');
  }

  static String _networkAuthHint() {
    return 'Network error during authentication. The device/emulator cannot reach Google/Firebase servers. Check internet and DNS, then retry.';
  }
}
