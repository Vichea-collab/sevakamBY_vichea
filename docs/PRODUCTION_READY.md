# Production Readiness Checklist

This file is the deployment checklist for `sevekamvichea` and includes secure Firebase rule templates for:
- Orders realtime (finder/provider)
- Chat realtime
- Profile data

## 1) Firebase project setup

Project:
- `sevekamvichea`

Required products:
- Authentication
- Firestore
- Storage
- (Recommended) App Check

### Authentication
1. Enable providers:
- Email/Password
- Google
2. Add authorized domains:
- `localhost`
- your production web domain(s)

### Android app
1. Firebase app package name must match:
- `com.example.servicefinder` (or your final release package)
2. Upload SHA-1 + SHA-256 for:
- debug keystore
- release keystore
3. Keep file in project:
- `android/app/google-services.json`

### iOS app
1. Bundle ID must match Xcode target.
2. Keep file in project:
- `ios/Runner/GoogleService-Info.plist`
3. Set in `ios/Flutter/FirebaseConfig.xcconfig`:
- `GOOGLE_REVERSED_CLIENT_ID`
- `GOOGLE_MAPS_API_KEY`

## 2) Google Maps production keys

Use separate keys:
1. Web key:
- Restriction: HTTP referrers
- APIs: Maps JavaScript API, Geocoding API
2. Android key:
- Restriction: Android apps (package + SHA-1)
- APIs: Maps SDK for Android, Geocoding API
3. iOS key:
- Restriction: iOS apps (bundle id)
- APIs: Maps SDK for iOS, Geocoding API

Your app already enforces Phnom Penh-only selection in code:
- `lib/presentation/pages/booking/address_map_picker_page.dart`

## 3) Firestore rules template (copy/paste)

Use this in Firebase Console -> Firestore Database -> Rules.

```rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function signedIn() {
      return request.auth != null;
    }

    function uid() {
      return request.auth.uid;
    }

    function hasRole(role) {
      return signedIn()
        && (
          request.auth.token.role == role
          || (request.auth.token.roles is list && request.auth.token.roles.hasAny([role]))
        );
    }

    function isAdmin() {
      return hasRole('admin');
    }

    function isSelf(userId) {
      return signedIn() && uid() == userId;
    }

    function isOrderParticipant() {
      return signedIn()
        && (
          resource.data.finderUid == uid()
          || resource.data.providerUid == uid()
        );
    }

    function chatDocPath(chatId) {
      return /databases/$(database)/documents/chats/$(chatId);
    }

    function chatExists(chatId) {
      return exists(chatDocPath(chatId));
    }

    function isChatParticipant(chatId) {
      return signedIn()
        && chatExists(chatId)
        && get(chatDocPath(chatId)).data.participants.hasAny([uid()]);
    }

    // Orders: allow realtime reads for participants only.
    match /orders/{orderId} {
      allow read: if isOrderParticipant() || isAdmin();
      allow create, update, delete: if false; // backend-only writes
    }

    // Chats: allow realtime reads for participants only.
    match /chats/{chatId} {
      allow read: if isChatParticipant(chatId) || isAdmin();
      allow create, update, delete: if false; // backend-only writes

      match /messages/{messageId} {
        allow read: if isChatParticipant(chatId) || isAdmin();
        allow create, update, delete: if false; // backend-only writes
      }
    }

    // User/profile data: own doc read, admin read.
    match /users/{userId} {
      allow read: if isSelf(userId) || isAdmin();
      allow create, update, delete: if false; // backend-only writes

      match /{subCollection=**}/{docId} {
        allow read: if isSelf(userId) || isAdmin();
        allow write: if false;
      }
    }

    match /finders/{userId} {
      allow read: if isSelf(userId) || isAdmin();
      allow write: if false;
    }

    match /providers/{userId} {
      allow read: if isSelf(userId) || isAdmin();
      allow write: if false;
    }

    // Public catalog reads (optional if you want direct client reads later).
    match /categories/{docId} {
      allow read: if true;
      allow write: if false;
    }

    match /services/{docId} {
      allow read: if true;
      allow write: if false;
    }

    // Everything else locked.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

## 4) Storage rules template (copy/paste)

Use this in Firebase Console -> Storage -> Rules.

```rules
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    function signedIn() {
      return request.auth != null;
    }

    function isSelf(userId) {
      return signedIn() && request.auth.uid == userId;
    }

    // Profile avatars (if you decide to upload directly from client in future).
    match /profile_avatars/{userId}/{fileName} {
      allow read: if true;
      allow write: if isSelf(userId)
        && request.resource != null
        && request.resource.size < 5 * 1024 * 1024
        && request.resource.contentType.matches('image/.*');
    }

    // Chat uploads are currently backend-managed (admin SDK + signed URLs).
    // Deny direct client access for safety.
    match /chat_uploads/{allPaths=**} {
      allow read, write: if false;
    }

    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

## 5) App Check production settings

1. Android:
- Enable Play Integrity provider.
2. iOS:
- Enable DeviceCheck/App Attest.
3. Web:
- Configure reCAPTCHA v3 site key.
4. Keep debug behavior:
- `FIREBASE_ENABLE_DEBUG_MOBILE_APP_CHECK=false` for normal local simulator runs.
- Set `true` only when explicitly testing debug App Check.

## 6) Android QA pass checklist (manual)

Run:
1. `cd lib/backend && node src/server.js`
2. `flutter run -d emulator-5554`

Test matrix:
1. Finder:
- sign in
- browse service/category
- booking flow end-to-end
- address picker + current location
- order list pagination
- submit rating/review
- receive notification when provider updates status
2. Provider:
- switch role
- view incoming/in-progress/history
- update order status transitions
- notification list
- chat with finder + image message
3. Admin:
- users/orders/posts/services/broadcasts screens load
- pagination/search work
- moderation actions return success

Pass criteria:
- no red-screen Flutter exceptions
- no repeated `setState() or markNeedsBuild() called during build`
- no `TextEditingController was used after being disposed`
- no role-forbidden loop retries

## 7) Known environment blockers

1. If backend is down, mobile API requests fail.
2. If emulator has poor network/Google Play Services issues, Firebase token requests may fail temporarily.
3. iOS simulator must be available on machine (`flutter devices` should list iOS).

