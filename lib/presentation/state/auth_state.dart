import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/firebase/firebase_bootstrap.dart';
import '../../domain/entities/profile_settings.dart';
import 'app_sync_state.dart';
import 'app_role_state.dart';
import 'chat_state.dart';
import 'finder_post_state.dart';
import 'home_promotion_state.dart';
import 'order_state.dart';
import 'profile_image_state.dart';
import 'provider_post_state.dart';
import 'push_notification_state.dart';
import 'subscription_state.dart';
import 'profile_settings_state.dart';
import 'user_notification_state.dart';

class AuthState {
  static final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  static final ValueNotifier<bool> ready = ValueNotifier(false);
  static const Duration _authOperationTimeout = Duration(seconds: 18);

  static bool _initialized = false;
  static StreamSubscription<User?>? _idTokenSubscription;

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
  );

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) {
      debugPrint('AuthState: Firebase not configured, skipping initialize');
      ready.value = true;
      return;
    }

    final auth = FirebaseAuth.instance;
    currentUser.value = auth.currentUser;
    debugPrint('AuthState: Initial user is ${auth.currentUser?.email ?? 'null'}');

    if (auth.currentUser != null) {
      await _syncSignedInUser(auth.currentUser!);
    } else {
      await AppSyncState.setSignedIn(false);
    }

    await _idTokenSubscription?.cancel();
    _idTokenSubscription = auth.idTokenChanges().listen(
      (user) async {
        debugPrint('AuthState: idTokenChanges emitted for ${user?.email ?? 'null'}');
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
    debugPrint('AuthState: Syncing signed in user ${user.email}');
    String token = '';
    try {
      token = await user.getIdToken() ?? '';
    } catch (error) {
      debugPrint('AuthState.getIdToken failed: $error');
    }
    _applyBackendTokenToStates(token);
    if (token.trim().isEmpty) {
      debugPrint('AuthState: Empty token, signing out sync');
      await AppSyncState.setSignedIn(false);
      return;
    }

    try {
      final roleResolved = await _alignRoleToRegisteredProfile();
      debugPrint('AuthState: Role resolution result: $roleResolved');

      if (!roleResolved) {
         debugPrint('AuthState: No role found during sync. Attempting default finder initialization...');
         try {
           await ProfileSettingsState.initUserRoleOnBackend(isProvider: false);
           final newToken = await user.getIdToken(true);
           _applyBackendTokenToStates(newToken ?? '');
           debugPrint('AuthState: Default finder initialization successful');
         } catch (e) {
           debugPrint('AuthState: Default initialization failed: $e');
         }
      }

      final isAdmin = await _isAdminSession(user);
      if (isAdmin) {
        debugPrint('AuthState: Admin session detected, signing out sync');
        await AppSyncState.setSignedIn(false);
        return;
      }

      debugPrint('AuthState: Refreshing states for user');
      await ChatState.refresh();
      await ChatState.refreshUnreadCount();
      await FinderPostState.refresh();
      await FinderPostState.refreshAllForLookup();
      await ProviderPostState.refresh();
      await ProviderPostState.refreshAllForLookup();
      await OrderState.refreshCurrentRole();
      await AppSyncState.setSignedIn(true);
      debugPrint('AuthState: Sync complete');
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
    debugPrint('AuthState: signInWithGoogle(isProvider: $isProvider, register: $registerIfMissing)');
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    try {
      final UserCredential result;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});
        result = await _runAuthOperation(
          operation: 'Google sign-in',
          action: () => FirebaseAuth.instance.signInWithPopup(provider),
        );
      } else {
        final GoogleSignInAccount? account = await _runAuthOperation(
          operation: 'Google account selection',
          action: () => _googleSignIn.signIn(),
          enforceTimeout: false,
        );
        if (account == null) {
          debugPrint('AuthState: Google sign-in canceled by user');
          return 'Google sign-in was canceled.';
        }

        debugPrint('AuthState: Google account selected: ${account.email}');
        final GoogleSignInAuthentication authentication = await account.authentication;
        final String? idToken = authentication.idToken;
        final String? accessToken = authentication.accessToken;

        if (idToken == null || idToken.isEmpty) {
          debugPrint('AuthState: Google idToken is missing');
          return 'Google sign-in token is missing. Check Firebase Google provider and Android OAuth SHA setup.';
        }

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: accessToken,
        );
        result = await _runAuthOperation(
          operation: 'Google sign-in',
          action: () => FirebaseAuth.instance.signInWithCredential(credential),
        );
      }

      final user = result.user;
      if (user == null) {
        debugPrint('AuthState: Firebase user is null after Google sign-in');
        return 'Google sign-in failed.';
      }

      debugPrint('AuthState: Google sign-in success for ${user.email}, applying session...');
      final sessionError = await _applyAuthenticatedSession(
        user,
        isProvider: isProvider,
        registerRoleIfMissing: registerIfMissing,
      );
      if (sessionError != null) {
        debugPrint('AuthState: Session application failed: $sessionError');
        return sessionError;
      }

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
      debugPrint('AuthState: Google sign-in flow complete');
      return null;
    } on FirebaseAuthException catch (error) {
      debugPrint('AuthState: FirebaseAuthException: code=${error.code}, message=${error.message}');
      return _friendlyAuthError(error, googleFlow: true);
    } catch (error) {
      debugPrint('AuthState: Google sign-in unexpected error: $error');
      return _friendlyUnknownGoogleError(error);
    }
  }

  static Future<String?> signInWithEmailPassword({
    required bool isProvider,
    required String email,
    required String password,
  }) async {
    debugPrint('AuthState: signInWithEmailPassword(email: $email, isProvider: $isProvider)');
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

      debugPrint('AuthState: Email sign-in success for ${user.email}, applying session...');
      final sessionError = await _applyAuthenticatedSession(
        user,
        isProvider: isProvider,
        registerRoleIfMissing: false,
      );
      if (sessionError != null) {
        debugPrint('AuthState: Session application failed: $sessionError');
        return sessionError;
      }

      await ProfileSettingsState.syncRoleProfileFromBackend(
        isProvider: isProvider,
      );
      debugPrint('AuthState: Email sign-in flow complete');
      return null;
    } on FirebaseAuthException catch (error) {
      debugPrint('AuthState: FirebaseAuthException: code=${error.code}, message=${error.message}');
      return _friendlyAuthError(error);
    } catch (error) {
      debugPrint('AuthState: Email sign-in unexpected error: $error');
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
    debugPrint('AuthState: signUpWithEmailPassword(email: $email, isProvider: $isProvider)');
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
        debugPrint('AuthState: Email already in use, attempting sign-in as fallback');
        final existing = await _runAuthOperation(
          operation: 'Existing account sign-in',
          action: () => FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          ),
        );
        user = existing.user;
      }

      if (user == null) {
        debugPrint('AuthState: User is null after registration/sign-in');
        return 'Sign-up failed.';
      }

      if (fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }

      debugPrint('AuthState: Registration success for ${user.email}, applying session...');
      final sessionError = await _applyAuthenticatedSession(
        user,
        isProvider: isProvider,
        registerRoleIfMissing: true,
      );
      if (sessionError != null) {
        debugPrint('AuthState: Session application failed: $sessionError');
        return sessionError;
      }

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
      debugPrint('AuthState: Sign-up flow complete');
      return null;
    } on FirebaseAuthException catch (error) {
      debugPrint('AuthState: FirebaseAuthException: code=${error.code}, message=${error.message}');
      return _friendlyAuthError(error);
    } catch (error) {
      debugPrint('AuthState: Sign-up unexpected error: $error');
      return _friendlyUnknownAuthError(error);
    }
  }

  static Future<void> signOut() async {
    debugPrint('AuthState: signing out');
    if (!FirebaseBootstrap.isConfigured) return;
    await FirebaseAuth.instance.signOut();
    try {
      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }
    } catch (_) {}
    _applyBackendTokenToStates('');
    await AppSyncState.setSignedIn(false);
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
    await ChatState.refreshUnreadCount();
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
    debugPrint('AuthState: Applying session (isProvider: $isProvider, register: $registerRoleIfMissing)');
    var token = await user.getIdToken(true);
    _applyBackendTokenToStates(token ?? '');

    bool initPerformed = false;
    if (registerRoleIfMissing) {
      try {
        debugPrint('AuthState: Initializing role on backend...');
        await ProfileSettingsState.initUserRoleOnBackend(isProvider: isProvider);
        initPerformed = true;
      } catch (e) {
        debugPrint('AuthState: Backend initialization failed: $e');
        return 'Backend registration failed. Check server connectivity and try again.';
      }
    }

    var hasRole = await ProfileSettingsState.hasRoleRegisteredOnBackend(
      isProvider: isProvider,
    );
    debugPrint('AuthState: Role registered on backend? $hasRole');

    if (!hasRole && !registerRoleIfMissing) {
      debugPrint('AuthState: Role missing during sign-in. Attempting auto-initialization...');
      try {
        await ProfileSettingsState.initUserRoleOnBackend(isProvider: isProvider);
        initPerformed = true;
        hasRole = await ProfileSettingsState.hasRoleRegisteredOnBackend(
          isProvider: isProvider,
        );
        debugPrint('AuthState: Auto-initialization result: $hasRole');
      } catch (e) {
        debugPrint('AuthState: Auto-initialization failed: $e');
      }
    }

    if (!hasRole) {
      debugPrint('AuthState: Final role check failed');
      return _missingRoleMessage(isProvider);
    }

    if (initPerformed) {
      debugPrint('AuthState: Forcing token refresh after initialization');
      token = await user.getIdToken(true);
      _applyBackendTokenToStates(token ?? '');
    }

    AppRoleState.setProvider(isProvider);
    await ChatState.refresh();
    await ChatState.refreshUnreadCount();
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

  static Future<bool> _alignRoleToRegisteredProfile() async {
    final currentIsProvider = AppRoleState.isProvider;
    final hasCurrentRole =
        await ProfileSettingsState.hasRoleRegisteredOnBackend(
          isProvider: currentIsProvider,
        );
    if (hasCurrentRole) return true;

    final fallbackIsProvider = !currentIsProvider;
    final hasFallbackRole =
        await ProfileSettingsState.hasRoleRegisteredOnBackend(
          isProvider: fallbackIsProvider,
        );
    if (hasFallbackRole) {
      AppRoleState.setProvider(fallbackIsProvider);
      return true;
    }
    return false;
  }

  static void _applyBackendTokenToStates(String token) {
    if (token.trim().isEmpty) {
      unawaited(PushNotificationState.unregisterCurrentToken());
    }
    ProfileSettingsState.setBackendToken(token);
    ChatState.setBackendToken(token);
    FinderPostState.setBackendToken(token);
    HomePromotionState.setBackendToken(token);
    ProviderPostState.setBackendToken(token);
    OrderState.setBackendToken(token);
    UserNotificationState.setBackendToken(token);
    SubscriptionState.setBackendToken(token);
    PushNotificationState.setBackendToken(token);
    if (token.trim().isNotEmpty) {
      unawaited(PushNotificationState.syncCurrentDeviceToken());
    }
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
