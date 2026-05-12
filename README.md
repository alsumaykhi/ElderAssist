# ElderAssist

<p align="center">
  <img src="ElderAssist_brand_kit/symbol/symbol_192.png" alt="ElderAssist symbol" width="120">
  <br>
  <img src="ElderAssist_brand_kit/wordmark/wordmark_horizontal_dark.png" alt="ElderAssist wordmark" width="360">
</p>

This repo is **ElderAssist**, a Flutter app I’m building for elder care: authentication, caregiver dashboards, medication tracking and adherence, check-ins, family/caregiver linking (including QR flows), in-app chat with a health assistant, and care-team messaging. It uses Firebase for backend services and push notifications.

### Brand reference

<p align="center">
  <img src="ElderAssist_brand_kit/brand_sheet.png" alt="ElderAssist brand sheet — colors, type, and logo usage" width="640">
</p>

<p align="center">
  <img src="ElderAssist_brand_kit/wordmark/wordmark_stacked.png" alt="ElderAssist stacked wordmark" width="200">
</p>

## Stack

| Layer | Technology |
|--------|------------|
| Client | Flutter (Dart 3.9+), `go_router`, `provider` |
| Auth & data | Firebase Auth, Cloud Firestore, Firebase Storage |
| Server logic | Cloud Functions (Node 20), Firebase Admin |
| AI | Vertex AI (via `@google-cloud/vertexai` in Functions) |
| Push | Firebase Cloud Messaging (`firebase_messaging`), local notifications |

## Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) (stable channel, SDK compatible with `pubspec.yaml`) — install this if you don’t have it yet; you’ll need it to run the app after cloning.
- A [Firebase](https://firebase.google.com/) project with Auth, Firestore, Storage, Functions, and FCM enabled as needed by your deployment
- [Firebase CLI](https://firebase.google.com/docs/cli) for emulators or Functions deploy
- Node.js 20 for Cloud Functions

## First time with Git & GitHub? (Windows)

These steps assume you’ve **never installed Git** and this is your **first time downloading code from GitHub**. If you already use Git, skip to [Local setup](#local-setup).

### 1. Create a GitHub account

1. Open **[github.com/signup](https://github.com/signup)** in your browser.
2. Choose a username, email, and password, and complete the sign-up flow.
3. **Confirm your email** when GitHub sends a verification message (check spam if you don’t see it).

### 2. Install Git on your computer

The **GitHub website** is where the repo lives in the cloud. **Git** is the program on your PC that **downloads** (“clones”) that repo to a folder you can open in Cursor, Android Studio, or VS Code.

1. Download **Git for Windows**: **[git-scm.com/download/win](https://git-scm.com/download/win)**.
2. Run the installer. For most people, the **default options** are fine (including “Git from the command line and also from 3rd-party software”).
3. When the installer finishes, close and reopen any open terminals.
4. Check that Git works: press **Win**, type **PowerShell**, open **Windows PowerShell**, then run:

   ```powershell
   git --version
   ```

   You should see something like `git version 2.43.0.windows.1`. If you get an error that `git` isn’t recognized, restart the PC and try again, or re-run the installer.

**Optional — GitHub Desktop (no command line):** If you prefer a graphical app, install **[GitHub Desktop](https://desktop.github.com/)**, sign in with your GitHub account, then use **File → Clone repository → URL**, paste the repository URL I give you, pick a folder, and click **Clone**. After that, open that folder in your editor and continue from [Local setup](#local-setup) at **Install Flutter dependencies**.

### 3. Clone this repository (download the code)

You need access to **this** repo: if it’s **private**, I have to add your GitHub username as a **collaborator** (Settings → Collaborators on the repo). If it’s public, you can clone without that.

**Using PowerShell (after Git is installed):**

1. Go to the folder where you want the project (example: your `Documents` folder):

   ```powershell
   cd $HOME\Documents
   ```

2. Clone — use the **exact URL** I send you (example below; yours might match):

   ```powershell
   git clone https://github.com/alsumaykhi/ElderAssist.git
   ```

3. Enter the project folder:

   ```powershell
   cd ElderAssist
   ```

**Signing in:** The first time you `git clone` over HTTPS, Windows may open a **sign-in window** for GitHub. If it asks for a password, GitHub **does not** use your normal account password anymore. Use a **[Personal Access Token](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)** (classic token with **repo** scope) as the password, or complete the browser OAuth flow if Git Credential Manager offers it.

After this succeeds, you’ll have a full copy of the code on your machine at the path you chose (e.g. `Documents\ElderAssist`).

## Local setup

1. **Open the cloned folder** in your editor (the directory that contains `pubspec.yaml` — that’s the Flutter project root).

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
