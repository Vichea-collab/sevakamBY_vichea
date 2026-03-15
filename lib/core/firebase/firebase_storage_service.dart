import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_bootstrap.dart';

class FirebaseStorageService {
  /// Uploads raw image bytes to a dedicated `avatars/` folder in Firebase Storage.
  /// Generates a unique filename based on the current user UID and timestamp.
  /// Returns the public download URL, or `null` if the upload fails or user is not signed in.
  static Future<String?> uploadProfileAvatar(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) {
      debugPrint(
        'FirebaseStorageService: Firebase not configured, cannot upload.',
      );
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        'FirebaseStorageService: No authenticated user, cannot upload avatar.',
      );
      return null;
    }

    try {
      final storage = FirebaseStorage.instance;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_$timestamp.$extension';
      final storageRef = storage.ref().child('avatars/$fileName');

      debugPrint(
        'FirebaseStorageService: Uploading $fileName (${bytes.length} bytes)...',
      );

      final String mimeType;
      switch (extension.toLowerCase()) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'heic':
        case 'heif':
          mimeType = 'image/heic';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          mimeType = 'image/jpeg';
      }

      final metadata = SettableMetadata(contentType: mimeType);

      final uploadTask = await storageRef.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint('FirebaseStorageService: Upload successful -> $downloadUrl');
      return downloadUrl;
    } catch (e, st) {
      debugPrint('FirebaseStorageService.uploadProfileAvatar error: $e');
      debugPrint(st.toString());
      return null;
    }
  } // This closing brace was missing for uploadProfileAvatar

  /// Uploads raw image bytes to a dedicated `portfolio/` folder in Firebase Storage.
  /// Generates a unique filename based on the current user UID and timestamp.
  /// Returns the public download URL, or `null` if the upload fails or user is not signed in.
  static Future<String?> uploadPortfolioPhoto(
    Uint8List bytes, {
    String extension = 'jpg',
  }) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) {
      debugPrint(
        'FirebaseStorageService: Firebase not configured, cannot upload.',
      );
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        'FirebaseStorageService: No authenticated user, cannot upload photo.',
      );
      return null;
    }

    try {
      final storage = FirebaseStorage.instance;

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${user.uid}_portfolio_$timestamp.$extension';
      final storageRef = storage.ref().child('portfolio/$fileName');

      debugPrint(
        'FirebaseStorageService: Uploading portfolio photo $fileName (${bytes.length} bytes)...',
      );

      final String mimeType;
      switch (extension.toLowerCase()) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          mimeType = 'image/jpeg';
      }

      final metadata = SettableMetadata(contentType: mimeType);

      final uploadTask = await storageRef.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      debugPrint(
        'FirebaseStorageService: Portfolio upload successful -> $downloadUrl',
      );
      return downloadUrl;
    } catch (e, st) {
      debugPrint('FirebaseStorageService.uploadPortfolioPhoto error: $e');
      debugPrint(st.toString());
      return null;
    }
  }

  static Future<String?> uploadProviderKycDocument(
    Uint8List bytes, {
    required String side,
    String extension = 'jpg',
  }) async {
    final configured = await FirebaseBootstrap.initializeIfConfigured();
    if (!configured) {
      debugPrint(
        'FirebaseStorageService: Firebase not configured, cannot upload KYC document.',
      );
      return null;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        'FirebaseStorageService: No authenticated user, cannot upload KYC document.',
      );
      return null;
    }

    try {
      final storage = FirebaseStorage.instance;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeSide = side.trim().toLowerCase() == 'back' ? 'back' : 'front';
      final fileName = '${user.uid}_kyc_${safeSide}_$timestamp.$extension';
      final storageRef = storage.ref().child('provider_kyc/$fileName');

      final String mimeType;
      switch (extension.toLowerCase()) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        case 'jpg':
        case 'jpeg':
        default:
          mimeType = 'image/jpeg';
      }

      final metadata = SettableMetadata(contentType: mimeType);
      final uploadTask = await storageRef.putData(bytes, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      debugPrint(
        'FirebaseStorageService: KYC $safeSide upload successful -> $downloadUrl',
      );
      return downloadUrl;
    } catch (e, st) {
      debugPrint('FirebaseStorageService.uploadProviderKycDocument error: $e');
      debugPrint(st.toString());
      return null;
    }
  }
}
