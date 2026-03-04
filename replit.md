# E-Kimina Rwanda - Digital Savings Group Platform

## Project Overview
A Flutter mobile app for Rwanda's digital savings groups (Ikimina). The app is built as a Flutter mobile application with a web version served via a Node.js static file server.

## Architecture
- **Language**: Dart/Flutter (mobile-first, compiled to web)
- **Frontend**: Flutter web (compiled to `build/web/`)
- **Server**: Node.js static file server (`server.js`)
- **Port**: 5000

## Project Structure
```
├── lib/                        # Flutter/Dart source code
│   ├── main.dart               # App entry point
│   ├── core/                   # Core utilities, services, config
│   │   ├── config/             # App configuration
│   │   ├── providers/          # Riverpod providers
│   │   ├── services/           # Services (FCM, analytics, etc.)
│   │   ├── theme/              # App theme
│   │   └── utils/              # Utilities
│   ├── data/                   # Data layer
│   │   ├── local/              # Hive local storage
│   │   └── remote/             # API client (Dio)
│   └── presentation/           # UI layer
│       ├── routes/             # GoRouter navigation
│       ├── screens/            # App screens
│       └── widgets/            # Reusable widgets
├── build/web/                  # Compiled Flutter web output
├── Rwanda/                     # Rwanda location data
│   └── data.json
├── assets/                     # Static assets (images, fonts, icons)
├── android/                    # Android build config
├── server.js                   # Node.js static server
├── package.json                # Node.js package config
└── pubspec.yaml                # Flutter dependencies
```

## Key Dependencies
- **State Management**: flutter_riverpod
- **Navigation**: go_router
- **HTTP**: dio + retrofit
- **Local Storage**: hive + hive_flutter
- **Firebase**: firebase_core, firebase_messaging, firebase_analytics
- **UI**: flutter_svg, lottie, flutter_animate, fl_chart, syncfusion_flutter_charts

## Setup Notes
- Flutter SDK 3.27.4 was downloaded to `/home/runner/flutter/` for building
- The web app requires: `export PATH="$PATH:/home/runner/flutter/bin" && flutter build web --release`
- Firebase initialization fails in web environments without proper Firebase config (google-services.json for Android already included)
- The `image_cropper_platform_interface` package was patched to replace `UnmodifiableUint8ListView` with `Uint8List.fromList` for Dart 3.x compatibility

## Running the App
The workflow runs `node server.js` which serves the pre-built Flutter web assets from `build/web/` on port 5000.

To rebuild after Dart code changes:
```bash
export PATH="$PATH:/home/runner/flutter/bin"
flutter build web --release
```
