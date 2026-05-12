# ElderAssist

ElderAssist is a Flutter application for elder care workflows: authentication, caregiver dashboards, medication tracking and adherence, check-ins, family/caregiver linking (including QR flows), in-app chat with a health assistant, and care-team messaging. It uses Firebase for backend services and push notifications.

## Stack

| Layer | Technology |
|--------|------------|
| Client | Flutter (Dart 3.9+), `go_router`, `provider` |
| Auth & data | Firebase Auth, Cloud Firestore, Firebase Storage |
| Server logic | Cloud Functions (Node 20), Firebase Admin |
| AI | Vertex AI (via `@google-cloud/vertexai` in Functions) |
| Push | Firebase Cloud Messaging (`firebase_messaging`), local notifications |

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, SDK compatible with `pubspec.yaml`)
- A [Firebase](https://firebase.google.com/) project with Auth, Firestore, Storage, Functions, and FCM enabled as needed by your deployment
- [Firebase CLI](https://firebase.google.com/docs/cli) for emulators or Functions deploy
- Node.js 20 for Cloud Functions

## Local setup

1. **Clone the repository** (after you have pushed it to GitHub).

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase / FlutterFire (required for a runnable app)**  
   This repository intentionally does **not** commit `lib/firebase_options.dart`, `android/app/google-services.json`, or `ios/Runner/GoogleService-Info.plist`. Generate them for your Firebase project:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Follow the CLI prompts and select your Firebase apps (Android / iOS / web as applicable). That recreates `firebase_options.dart` and the platform config files locally.

4. **Run the app**

   ```bash
   flutter run
   ```

5. **Cloud Functions (optional)**  
   From the `functions/` directory:

   ```bash
   cd functions
   npm install
   ```

   Use `npm run serve` with the Firebase emulator or deploy with your own Firebase project configuration (not committed: `.firebaserc`, service account JSONs).

## Security notes

- Do not commit signing keystores (`.jks`, `.keystore`), `key.properties`, or Google Cloud service account JSON files.
- Keep `.env` / `.env.local` out of git if you introduce them for secrets or endpoints.

## Repository name

The Flutter package name in `pubspec.yaml` may differ from the GitHub repository name (for example `elderassist` on GitHub). The app branding and product name are **ElderAssist**.
