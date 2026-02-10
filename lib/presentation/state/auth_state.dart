import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/app_env.dart';
import '../../core/firebase/firebase_bootstrap.dart';
import '../../domain/entities/profile_settings.dart';
import 'app_role_state.dart';
import 'finder_post_state.dart';
import 'profile_settings_state.dart';

class AuthState {
  static final ValueNotifier<User?> currentUser = ValueNotifier<User?>(null);
  static final ValueNotifier<bool> ready = ValueNotifier(false);

  static bool _initialized = false;
  static bool _googleInitialized = false;

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
      final token = await auth.currentUser!.getIdToken();
      ProfileSettingsState.setBackendToken(token ?? '');
      FinderPostState.setBackendToken(token ?? '');
      await FinderPostState.refresh();
    }
    auth.authStateChanges().listen((user) async {
      currentUser.value = user;
      if (user == null) {
        ProfileSettingsState.setBackendToken('');
        FinderPostState.setBackendToken('');
        return;
      }
      final token = await user.getIdToken();
      ProfileSettingsState.setBackendToken(token ?? '');
      FinderPostState.setBackendToken(token ?? '');
      await FinderPostState.refresh();
    });
    ready.value = true;
  }

  static bool get isSignedIn => currentUser.value != null;

  static Future<String?> signInWithGoogle({required bool isProvider}) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) return FirebaseBootstrap.setupHint();

    try {
      final UserCredential result;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()..addScope('email');
        result = await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        await _ensureGoogleInitialized();
        final account = await GoogleSignIn.instance.authenticate();
        final authentication = account.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: authentication.idToken,
        );
        result = await FirebaseAuth.instance.signInWithCredential(credential);
      }
      final user = result.user;
      if (user == null) return 'Google sign-in failed.';
      await _applyAuthenticatedSession(user, isProvider: isProvider);

      final fullName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : (isProvider ? 'Service Provider' : 'Service Finder');
      final email = user.email?.trim() ?? '';
      await _seedProfileAfterRegistration(
        isProvider: isProvider,
        fullName: fullName,
        email: email,
      );
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
      await _applyAuthenticatedSession(user, isProvider: isProvider);
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
      final result = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = result.user;
      if (user == null) return 'Sign-up failed.';
      if (fullName.trim().isNotEmpty) {
        await user.updateDisplayName(fullName.trim());
      }
      await _applyAuthenticatedSession(user, isProvider: isProvider);
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
    ProfileSettingsState.setBackendToken('');
    FinderPostState.setBackendToken('');
  }

  static Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    final webClientId = AppEnv.firebaseWebClientId();
    await GoogleSignIn.instance.initialize(
      serverClientId: webClientId.isEmpty ? null : webClientId,
    );
    _googleInitialized = true;
  }

  static Future<void> _applyAuthenticatedSession(
    User user, {
    required bool isProvider,
  }) async {
    final token = await user.getIdToken(true);
    ProfileSettingsState.setBackendToken(token ?? '');
    FinderPostState.setBackendToken(token ?? '');
    AppRoleState.setProvider(isProvider);
    await ProfileSettingsState.initUserRoleOnBackend(isProvider: isProvider);
    await FinderPostState.refresh();
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
