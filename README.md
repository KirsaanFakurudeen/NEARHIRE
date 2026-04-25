# NearHire 📍

> **Hyperlocal GPS-based job discovery platform** — connecting job seekers with employers nearby in real time.

---

## Overview

NearHire is a Flutter mobile application that lets employers post local job listings and job seekers discover opportunities within a configurable radius of their current location. Built with Firebase as the backend, it supports real-time chat, push notifications, resume uploads, and role-based access.

---

## Features

### Job Seeker
- 📍 Discover jobs within a customizable GPS radius
- 🗺️ Map and list view of nearby jobs
- ⚡ One-tap apply, resume upload, or chat-first application
- 📋 Track application status in real time
- 💬 In-app chat with employers

### Employer
- 📝 Post job listings with location pinned to GPS
- 👥 View and manage applicants per listing
- ✅ Accept / reject applications
- 📊 Dashboard with active jobs, application count, and hire stats
- 💬 In-app chat with applicants

### Shared
- 🔐 Email/Password and Phone OTP authentication
- 👤 Profile management (seeker skills & availability / employer business info)
- 🔔 Push notifications via Firebase Cloud Messaging
- ⭐ Rating system
- 🚩 Report system

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart) |
| Auth | Firebase Authentication |
| Database | Cloud Firestore |
| Storage | Firebase Storage |
| Notifications | Firebase Cloud Messaging |
| State Management | Provider |
| Location | Geolocator + Geocoding |
| Maps | Google Maps Flutter |

---

## Project Structure

```
lib/
├── core/
│   ├── constants/       # App-wide constants
│   ├── services/        # Firebase Auth, Location, Notifications
│   ├── theme/           # App theme
│   └── utils/           # Validators, formatters, distance helper
├── models/              # User, Job, Application, Message, etc.
├── providers/           # Auth, Job, Application, Chat, Location
├── screens/
│   ├── auth/            # Splash, Login, Register, OTP, Role Selection
│   ├── employer/        # Dashboard, Post Job, Manage Listings, Applications
│   ├── seeker/          # Dashboard, Job Detail, Apply, Application Status
│   └── shared/          # Chat, Profile, Notifications, Rating, Report
└── widgets/             # Reusable UI components
```

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) `>=3.0.0`
- [Firebase CLI](https://firebase.google.com/docs/cli) installed and logged in
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/) installed
- A Firebase project with the following enabled:
  - Authentication → Email/Password + Phone
  - Cloud Firestore
  - Firebase Storage
  - Firebase Cloud Messaging

### Setup

**1. Clone the repository**
```bash
git clone https://github.com/KirsaanFakurudeen/NEARHIRE.git
cd NEARHIRE
```

**2. Install dependencies**
```bash
flutter pub get
```

**3. Connect Firebase**

Log in to Firebase CLI with the account that owns the project:
```bash
firebase login
```

Run FlutterFire configure to generate the required Firebase config files:
```bash
flutterfire configure --project=<your-firebase-project-id> --platforms=android,ios
```

This will generate:
- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

**4. Add Google Maps API Key**

In `lib/core/constants/app_constants.dart`, replace:
```dart
static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
```

Also add the key to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
  android:name="com.google.android.geo.API_KEY"
  android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
```

**5. Deploy Firestore rules and indexes**
```bash
firebase deploy --only firestore --project=<your-firebase-project-id>
```

**6. Run the app**
```bash
flutter run
```

---

## Firestore Collections

| Collection | Description |
|---|---|
| `users` | User profiles (seeker & employer) |
| `jobs` | Job listings posted by employers |
| `applications` | Applications submitted by seekers |
| `messages` | Chat messages per application |

---

## Environment & Sensitive Files

The following files are **not committed** to this repository and must be generated locally:

| File | How to get it |
|---|---|
| `lib/firebase_options.dart` | Run `flutterfire configure` |
| `android/app/google-services.json` | Run `flutterfire configure` |
| `ios/Runner/GoogleService-Info.plist` | Run `flutterfire configure` |
| `firestore.rules` | Provided separately / run `firebase deploy` |
| `firestore.indexes.json` | Provided separately / run `firebase deploy` |
| `firebase.json` | Provided separately |

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## License

This project is private and not licensed for public use.
