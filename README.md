# servicefinder

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Google Maps Setup

To enable map search by location name and current location in booking flow:

1. Set your API key in root `.env`:
   - `GOOGLE_MAPS_API_KEY=...`
2. Android: add `GOOGLE_MAPS_API_KEY=...` into `android/local.properties`
   (see `android/local.properties.example`).
3. iOS: copy `ios/Flutter/FirebaseConfig.xcconfig.example` to
   `ios/Flutter/FirebaseConfig.xcconfig` and set `GOOGLE_MAPS_API_KEY`.
4. Web:
   - `web/index.html`: replace `YOUR_GOOGLE_MAPS_API_KEY`

The map picker is Cambodia-focused and supports:
- City quick chips
- Search by location name
- Use current location

## Backend + Firebase Auth Setup

Backend:
1. Copy `lib/backend/.env.example` to `lib/backend/.env`.
2. Set:
   - `FIREBASE_SERVICE_ACCOUNT_PATH`
   - `FIREBASE_STORAGE_BUCKET`
3. Start backend:
   - `cd lib/backend`
   - `npm install`
   - `npm run dev`

Flutter app (Google Sign-In + Firebase token to backend):
1. Copy `.env.example` to `.env`.
2. Fill:
   - `API_BASE_URL` (example: `http://localhost:5000`)
   - `GOOGLE_MAPS_API_KEY`
   - `FIREBASE_API_KEY`
   - `FIREBASE_APP_ID`
   - `FIREBASE_MESSAGING_SENDER_ID`
   - `FIREBASE_PROJECT_ID`
   - Optional: `FIREBASE_AUTH_DOMAIN`, `FIREBASE_STORAGE_BUCKET`, `FIREBASE_IOS_CLIENT_ID`, `FIREBASE_IOS_BUNDLE_ID`, `FIREBASE_MEASUREMENT_ID`
3. Android Firebase:
   - Add Firebase Android app with package `com.example.servicefinder` (or your real package).
   - Download `google-services.json` and place it at `android/app/google-services.json`.
   - Add SHA-1 and SHA-256 fingerprints in Firebase Console.
4. iOS Firebase:
   - Add Firebase iOS app with your iOS bundle id.
   - Download `GoogleService-Info.plist` and place it at `ios/Runner/GoogleService-Info.plist`.
   - Copy `ios/Flutter/FirebaseConfig.xcconfig.example` to `ios/Flutter/FirebaseConfig.xcconfig`
     and set `GOOGLE_REVERSED_CLIENT_ID` from `GoogleService-Info.plist` (`REVERSED_CLIENT_ID`).
5. Install dependencies and run:
   - `flutter pub get`
   - `cd ios && pod install && cd ..` (for iOS)
   - `flutter run`
