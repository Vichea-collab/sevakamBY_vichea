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
      final user = auth.currentUser!;
      final token = await user.getIdToken();
      _applyBackendTokenToStates(token ?? '');
      await _alignRoleToRegisteredProfile();
      final isAdmin = await _isAdminSession(user);
      if (isAdmin) {
        await AppSyncState.setSignedIn(false);
      } else {
        await ChatState.refresh();
        await FinderPostState.refresh();
        await FinderPostState.refreshAllForLookup();
        await ProviderPostState.refresh();
        await ProviderPostState.refreshAllForLookup();
        await OrderState.refreshCurrentRole();
        await AppSyncState.setSignedIn(true);
      }
    } else {
      await AppSyncState.setSignedIn(false);
    }
    await _idTokenSubscription?.cancel();
    _idTokenSubscription = auth.idTokenChanges().listen((user) async {
      currentUser.value = user;
      if (user == null) {
        _applyBackendTokenToStates('');
        await AppSyncState.setSignedIn(false);
        return;
      }
      final token = await user.getIdToken();
      _applyBackendTokenToStates(token ?? '');
      await _alignRoleToRegisteredProfile();
      final isAdmin = await _isAdminSession(user);
      if (isAdmin) {
        await AppSyncState.setSignedIn(false);
      } else {
        await ChatState.refresh();
        await FinderPostState.refresh();
        await FinderPostState.refreshAllForLookup();
        await ProviderPostState.refresh();
        await ProviderPostState.refreshAllForLookup();
        await OrderState.refreshCurrentRole();
        await AppSyncState.setSignedIn(true);
      }
    });
    ready.value = true;
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
      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        provider.setCustomParameters({'prompt': 'select_account'});
        result = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await _ensureGoogleInitialized();
        await _resetGoogleSessionForAccountChooser();
        final account = await GoogleSignIn.instance.authenticate();
        final authentication = account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: authentication.idToken,
        );
        result = await FirebaseAuth.instance.signInWithCredential(credential);
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
    } on GoogleSignInException catch (error) {
      debugPrint(
        'GoogleSignInException: code=${error.code}, desc=${error.description}, details=${error.details}',
      );
      return _friendlyGoogleSignInError(error);
    } on FirebaseAuthException catch (error) {
      debugPrint(
        'FirebaseAuthException (google credential): code=${error.code}, message=${error.message}',
      );
      return _friendlyAuthError(error);
    } catch (error) {
      debugPrint('Google sign-in unexpected error: $error');
      return error.toString();
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
      final result = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
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
      return error.toString();
    }
  }

  static Future<String?> sendPasswordResetEmail({required String email}) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    final trimmed = email.trim();
    if (trimmed.isEmpty) return 'Email is required.';

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: trimmed);
      return null;
    } on FirebaseAuthException catch (error) {
      return _friendlyAuthError(error);
    } catch (error) {
      return error.toString();
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
        final result = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: email.trim(),
              password: password,
            );
        user = result.user;
      } on FirebaseAuthException catch (error) {
        if (error.code != 'email-already-in-use') rethrow;
        final existing = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
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
      return error.toString();
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

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final webClientId = AppEnv.firebaseWebClientId();
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );
    _googleInitialized = true;
  }

  static Future<void> _resetGoogleSessionForAccountChooser() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
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

  static String _friendlyAuthError(FirebaseAuthException error) {
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
        return 'Network error. Please check your internet connection.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Authentication failed.';
    }
  }

  static String _friendlyGoogleSignInError(GoogleSignInException error) {
    final details = error.details?.toString().trim() ?? '';
    String withDetails(String message) {
      if (details.isEmpty) return message;
      return '$message ($details)';
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
        return 'Google sign-in was canceled.';
      case GoogleSignInExceptionCode.interrupted:
        return withDetails('Google sign-in was interrupted. Please try again.');
      case GoogleSignInExceptionCode.uiUnavailable:
        return withDetails('Google sign-in UI is unavailable on this device.');
      case GoogleSignInExceptionCode.userMismatch:
        return withDetails(
          'Google account mismatch detected. Please sign out and retry.',
        );
      case GoogleSignInExceptionCode.unknownError:
        final desc = error.description?.trim() ?? '';
        return desc.isNotEmpty
            ? withDetails('Google sign-in failed: $desc')
            : withDetails('Google sign-in failed.');
    }
  }
}
