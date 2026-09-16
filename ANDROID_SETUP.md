# Android setup for Qify Authenticator

## 1. Firebase configuration

Run:

```bash
flutterfire configure
```

Select your Firebase project and Android platform. Keep the generated:

```text
lib/firebase_options.dart
```

## 2. Enable Email/Password

Firebase Console -> Authentication -> Sign-in method -> Email/Password -> Enable.

## 3. Create Firestore

Firebase Console -> Firestore Database -> Create database.

Use the included `firestore.rules` instead of open test rules once the database is created.

## 4. Camera permission

In `android/app/src/main/AndroidManifest.xml`, add this immediately inside `<manifest ...>`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
```

## 5. Android minimum SDK

The current `local_auth` package supports Android SDK 24 and above. If your generated project uses a lower minimum SDK, change the app module's minSdk to 24.

For a Groovy Gradle file:

```gradle
android {
    defaultConfig {
        minSdkVersion 24
    }
}
```

For Kotlin DSL, use the corresponding `minSdk = 24` setting in `defaultConfig`.
