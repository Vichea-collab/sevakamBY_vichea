# Sevakam

Sevakam is a multi-role service marketplace built with Flutter, Node.js, and Firebase. The project includes a customer experience for finders, a service-management experience for providers, a separate admin web interface, and a backend API for business logic, moderation, and integrations.

Demo Link: https://youtu.be/XQkM15e58p0

Android Apk File: https://drive.google.com/drive/folders/1ENl0Lc5hyUrDiO9ztjAuO_7Byq-87siv?usp=sharing

## Overview

- `Finder app`: browse providers, book services, chat, pay, and review completed work
- `Provider app`: manage profile, publish offers, receive bookings, and update order status
- `Admin web`: monitor platform activity, moderate content, manage tickets, and publish broadcasts
- `Backend API`: handles authenticated business flows and Firebase Admin operations

## Technology Stack

- `Frontend`: Flutter
- `Admin frontend`: Flutter web entrypoint
- `Backend`: Node.js + Express
- `Database`: Firebase Firestore
- `Storage`: Firebase Storage
- `Authentication`: Firebase Authentication
- `Notifications`: Firebase Cloud Messaging
- `Maps`: Google Maps
- `Payments`: Bakong(future work) / payment gateway integrations

## Repository Structure

```text
.
├── android/                     Android project
├── ios/                         iOS project
├── assets/                      App assets
├── docs/                        Project documentation and diagrams
├── lib/
│   ├── admin/                   Admin web app
│   ├── backend/                 Node.js backend API
│   ├── core/                    Shared config, theme, utilities, Firebase bootstrap
│   ├── data/                    Data sources, API clients, repositories
│   ├── domain/                  Domain entities and repository contracts
│   └── presentation/            Mobile/web UI pages, widgets, and state
├── pubspec.yaml                 Flutter package manifest
└── README.md
```

## Prerequisites

- Flutter `3.38.x` or compatible stable release
- Dart `3.10.x`
- Xcode with CocoaPods for iOS builds
- Android Studio / Android SDK for Android builds
- Node.js `18+` for the backend
- A configured Firebase project

## Application Setup

### 1. Install Flutter dependencies

```bash
flutter pub get
```

### 2. Configure the Flutter environment

Copy the template and update values as needed:

```bash
cp .env.example .env
```

Key variables:

- `API_BASE_URL`
- `API_BASE_URL_IOS`
- `API_BASE_URL_ANDROID`
- `GOOGLE_MAPS_WEB_API_KEY`
- `GOOGLE_MAPS_ANDROID_API_KEY`
- `GOOGLE_MAPS_IOS_API_KEY`
- `FIREBASE_API_KEY`
- `FIREBASE_APP_ID`
- `FIREBASE_MESSAGING_SENDER_ID`
- `FIREBASE_PROJECT_ID`
- `FIREBASE_STORAGE_BUCKET`
- `FIREBASE_IOS_CLIENT_ID`
- `FIREBASE_IOS_BUNDLE_ID`
- `FIREBASE_WEB_CLIENT_ID`
- `FIREBASE_RECAPTCHA_V3_SITE_KEY`
- `FIREBASE_ENABLE_DEBUG_MOBILE_APP_CHECK`
- `FIREBASE_ENABLE_IOS_APP_CHECK`

Notes:

- Android emulator localhost is rewritten to `10.0.2.2` automatically.
- For iOS physical-device local API access, use a reachable hostname such as `http://YOUR-MAC.local:5050`.
- iOS App Check is skipped by default for local device runs unless `FIREBASE_ENABLE_IOS_APP_CHECK=true`.

## Native Firebase Configuration

### Android

1. Place `google-services.json` at `android/app/google-services.json`.
2. Ensure the Firebase Android app package matches `applicationId` in `android/app/build.gradle.kts`.
3. Add SHA-1 and SHA-256 fingerprints in Firebase for Google Sign-In.

### iOS

1. Place `GoogleService-Info.plist` at `ios/Runner/GoogleService-Info.plist`.
2. Copy the iOS config template:

```bash
cp ios/Flutter/FirebaseConfig.xcconfig.example ios/Flutter/FirebaseConfig.xcconfig
```

3. Set:
   - `GOOGLE_REVERSED_CLIENT_ID`
   - `GOOGLE_MAPS_API_KEY`
4. Install pods:

```bash
cd ios && pod install && cd ..
```

Local iPhone note:

- Push/APNs capability is currently disabled in the project so the app can run with a personal Apple development team.

## Backend Setup

### 1. Configure the backend environment

```bash
cp lib/backend/.env.example lib/backend/.env
```

Required backend variables:

- `FIREBASE_SERVICE_ACCOUNT_PATH`
- `FIREBASE_STORAGE_BUCKET`

### 2. Install backend dependencies

```bash
cd lib/backend
npm install
```

### 3. Start the backend

```bash
npm run dev
```

Useful backend scripts:

```bash
npm run start
npm run seed:admin
npm run seed:demo
npm run clean:support-chats
```

## Running the Project

### Mobile and Web App

```bash
flutter run -d chrome
flutter run -d emulator-5554
flutter run -d ios
```

### Admin Web

```bash
flutter run -d chrome -t lib/admin/main.dart --web-port=8099
```

## Quality Checks

Run these before shipping changes:

```bash
flutter analyze
flutter test
```

Recommended manual smoke checks:

- Email and Google sign-in
- Finder / provider role flows
- Booking creation and status updates
- Chat send / receive with image upload
- Notifications and promotion visibility
- Provider ratings and review display
- Admin moderation and support ticket actions

## Local Development Notes

- If the backend is not running, API requests will fail.
- Firestore realtime listeners may fall back to backend API responses depending on rules and environment.
- Web App Check is skipped in debug mode by design.
- Mobile debug App Check is disabled by default unless explicitly enabled.
- The iOS `26.0` simulator currently has runtime issues with one transitive dependency. Use a physical iPhone or the `iOS 18.6` simulator for reliable local testing.

## Maps Behavior

The booking address picker is constrained to Cambodia and defaults to Phnom Penh:

- Taps outside Cambodia are rejected
- Current location outside Cambodia is rejected
- Search results are constrained to Cambodia
- iOS Simulator uses the simulator location, not the Mac's GPS

Implementation reference:

- `lib/presentation/pages/booking/address_map_picker_page.dart`

## Documentation

- Production checklist: `docs/PRODUCTION_READY.md`
- Data flow diagrams: `docs/DATA_FLOW_DIAGRAM.md`
- Simplified presentation diagram: `docs/DATA_FLOW_DIAGRAM_SIMPLE.md`

## License

This repository is currently private / project-specific. Add a formal license if the project will be distributed publicly.
