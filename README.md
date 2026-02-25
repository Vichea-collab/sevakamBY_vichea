# Servicefinder

Multi-role service marketplace app:
- Finder app flow
- Provider app flow
- Admin panel
- Backend API (Node + Firebase Admin)

Targets:
- Web
- Android
- iOS

## 1) Environment setup

### Flutter app
1. Copy `.env.example` to `.env`.
2. Set API URL:
   - Local dev: `API_BASE_URL=http://localhost:5050`
3. Set Google Maps keys:
   - `GOOGLE_MAPS_WEB_API_KEY`
   - `GOOGLE_MAPS_ANDROID_API_KEY`
   - `GOOGLE_MAPS_IOS_API_KEY`
   - `GOOGLE_MAPS_API_KEY` is backward-compatible fallback.
4. Set Firebase keys:
   - Shared fallback: `FIREBASE_API_KEY`, `FIREBASE_APP_ID`
   - Platform overrides:
     - `FIREBASE_WEB_API_KEY`, `FIREBASE_WEB_APP_ID`
     - `FIREBASE_ANDROID_API_KEY`, `FIREBASE_ANDROID_APP_ID`
     - `FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID`
   - Required:
     - `FIREBASE_MESSAGING_SENDER_ID`
     - `FIREBASE_PROJECT_ID`
   - Recommended:
     - `FIREBASE_AUTH_DOMAIN`
     - `FIREBASE_STORAGE_BUCKET`
     - `FIREBASE_IOS_CLIENT_ID`
     - `FIREBASE_IOS_BUNDLE_ID`
     - `FIREBASE_WEB_CLIENT_ID`
     - `FIREBASE_RECAPTCHA_V3_SITE_KEY`
     - `FIREBASE_ENABLE_DEBUG_MOBILE_APP_CHECK` (optional, default false)

### Backend
1. Copy `lib/backend/.env.example` to `lib/backend/.env`.
2. Set:
   - `FIREBASE_SERVICE_ACCOUNT_PATH`
   - `FIREBASE_STORAGE_BUCKET`
3. Start backend:
   - `cd lib/backend`
   - `npm install`
   - `node src/server.js`

## 2) Native Firebase files

### Android
1. Put `google-services.json` at `android/app/google-services.json`.
2. Ensure package name in Firebase matches `applicationId` in `android/app/build.gradle.kts`.
3. Add SHA-1 and SHA-256 fingerprints in Firebase Console for Google Sign-In.

### iOS
1. Put `GoogleService-Info.plist` at `ios/Runner/GoogleService-Info.plist`.
2. Copy `ios/Flutter/FirebaseConfig.xcconfig.example` to `ios/Flutter/FirebaseConfig.xcconfig`.
3. Set:
   - `GOOGLE_REVERSED_CLIENT_ID` from `GoogleService-Info.plist` (`REVERSED_CLIENT_ID`)
   - `GOOGLE_MAPS_API_KEY` for iOS SDK map rendering
4. Run:
   - `cd ios && pod install && cd ..`

## 3) Google Maps key restrictions (production)

Use separate keys by platform.

1. Web key:
   - Restriction: HTTP referrers
   - Allowed APIs: Maps JavaScript API, Geocoding API (if used client-side)
2. Android key:
   - Restriction: Android apps (package + SHA-1)
   - Allowed APIs: Maps SDK for Android, Geocoding API
3. iOS key:
   - Restriction: iOS apps (bundle id)
   - Allowed APIs: Maps SDK for iOS, Geocoding API

## 4) Phnom Penh-only map behavior

Booking map picker is restricted to Phnom Penh:
- Tap outside Phnom Penh is blocked.
- Current-location outside Phnom Penh is rejected and reset.
- Search queries are constrained to Phnom Penh/Cambodia.

Main implementation:
- `lib/presentation/pages/booking/address_map_picker_page.dart`

## 5) Run commands

1. Install Flutter dependencies:
   - `flutter pub get`
2. Start backend:
   - `cd lib/backend && node src/server.js`
3. Run web:
   - `flutter run -d chrome`
4. Run Android emulator:
   - `flutter run -d emulator-5554`
5. Run iOS simulator:
   - `flutter run -d ios`

## 6) QA baseline

1. Static checks:
   - `flutter analyze`
   - `flutter test`
2. Manual smoke checks:
   - Auth (email + Google)
   - Role switch (finder/provider)
   - Booking flow end-to-end
   - Provider order status update -> finder notification
   - Chat send/receive + image upload
   - Provider review/rating submission and profile review list
   - Admin post stream and moderation actions

## 7) Known local-dev behavior

1. If backend is not running, mobile/API calls fail with connection refused.
2. Firestore realtime listeners may show permission warnings and fallback to backend APIs depending on rules.
3. Web App Check is skipped in debug mode by design.
4. Mobile App Check is skipped in debug mode by default unless
   `FIREBASE_ENABLE_DEBUG_MOBILE_APP_CHECK=true`.

## 8) Production guide

Use:
- `docs/PRODUCTION_READY.md`
