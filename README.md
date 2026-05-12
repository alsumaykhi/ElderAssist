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

3. **Firebase client config (required for a runnable app)**  
   This repository does **not** commit `lib/firebase_options.dart`, `android/app/google-services.json`, or `ios/Runner/GoogleService-Info.plist`. Use one of the following.

   **Option A (recommended): FlutterFire CLI**  
   Ask the project owner to invite you to the Firebase project, then run:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Follow the prompts and select the Android / iOS (and web, if used) apps. That generates `firebase_options.dart` and the platform config files locally.

   **Option B (manual handoff from the project owner)**  
   The owner sends these files over a **private** channel (not in a public GitHub issue). Place them at **exact** paths inside the clone:

   | File | Path in the repo |
   |------|------------------|
   | `firebase_options.dart` | `lib/firebase_options.dart` |
   | `google-services.json` | `android/app/google-services.json` |
   | `GoogleService-Info.plist` | `ios/Runner/GoogleService-Info.plist` *(only if building iOS)* |

   Then run `flutter pub get` and `flutter run`. **Do not commit** these files; they stay local and are listed in `.gitignore`.

   If the owner changes Firebase app registration, Android `applicationId`, iOS bundle ID, or switches Firebase project, **send updated files** (or use Option A and run `flutterfire configure` again). Otherwise the app can fail at runtime or point at the wrong project.

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

## Firebase CLI deploy vs local client files

Running `firebase deploy` (Functions, Firestore rules, indexes, Hosting, etc.) updates **cloud resources** for the linked Firebase project. It does **not** update `firebase_options.dart`, `google-services.json`, or `GoogleService-Info.plist` on anyone’s machine. Collaborators using **Option B** keep the same handoff files until the owner changes client-side Firebase setup or sends replacements; backend-only deploys usually do not require new handoff files.

## Security notes

- Do not commit signing keystores (`.jks`, `.keystore`), `key.properties`, or Google Cloud service account JSON files.
- Keep `.env` / `.env.local` out of git if you introduce them for secrets or endpoints.

## Repository name

The Flutter package name in `pubspec.yaml` may differ from the GitHub repository name (for example `elderassist` on GitHub). The app branding and product name are **ElderAssist**.
