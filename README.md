# ElderAssist

This repo is **ElderAssist**, a Flutter app I’m building for elder care: authentication, caregiver dashboards, medication tracking and adherence, check-ins, family/caregiver linking (including QR flows), in-app chat with a health assistant, and care-team messaging. It uses Firebase for backend services and push notifications.

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

1. **Clone this repository** from GitHub.

2. **Install Flutter dependencies**

   ```bash
   flutter pub get
   ```

3. **Firebase client config (required for a runnable app)**  
   I don’t commit `lib/firebase_options.dart`, `android/app/google-services.json`, or `ios/Runner/GoogleService-Info.plist` to this repo. If you’re collaborating with me on the app, I’ll send you these files directly over a **private** channel (please don’t put them in a public GitHub issue or gist). Drop them into your clone at these **exact** paths:

   | File | Path in the repo |
   |------|------------------|
   | `firebase_options.dart` | `lib/firebase_options.dart` |
   | `google-services.json` | `android/app/google-services.json` |
   | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` *(only if you’re building iOS)* |

   Then run `flutter pub get` and `flutter run`. **Don’t commit** these files—they’re in `.gitignore` on purpose.

   If I change Firebase app registration, the Android `applicationId`, the iOS bundle ID, or move the project to another Firebase project, I’ll send you **updated** copies. Until then, keep using the set I gave you; otherwise the build can break or point at the wrong backend.

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

   Use `npm run serve` with the Firebase emulator if you’re working on Functions. I don’t commit `.firebaserc` or service account JSONs; you’ll set those up locally only if you need to deploy from your machine.

## Firebase CLI deploy vs the files I send you

When I run `firebase deploy` (Functions, Firestore rules, indexes, Hosting, etc.), that updates **cloud** resources for my Firebase project. It does **not** change `firebase_options.dart`, `google-services.json`, or `GoogleService-Info.plist` on your computer. You keep using the copies I sent until I change something on the client/Firebase registration side and give you new files. Pure backend deploys usually don’t require a new handoff.

## Security notes

- Do not commit signing keystores (`.jks`, `.keystore`), `key.properties`, or Google Cloud service account JSON files.
- Keep `.env` / `.env.local` out of git if you introduce them for secrets or endpoints.

## Repository name

The Flutter package name in `pubspec.yaml` may differ from this GitHub repository’s name. The product name I use is **ElderAssist**.
