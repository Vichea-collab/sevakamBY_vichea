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

1. Set your API key:
   - `web/index.html`: replace `YOUR_GOOGLE_MAPS_API_KEY`
   - `android/app/src/main/AndroidManifest.xml`: replace `YOUR_GOOGLE_MAPS_API_KEY`
   - `ios/Runner/AppDelegate.swift`: replace `YOUR_GOOGLE_MAPS_API_KEY`
2. For geocoding search requests, run with:
   - `flutter run -d chrome --dart-define=GOOGLE_MAPS_API_KEY=YOUR_GOOGLE_MAPS_API_KEY`

The map picker is Cambodia-focused and supports:
- City quick chips
- Search by location name
- Use current location
