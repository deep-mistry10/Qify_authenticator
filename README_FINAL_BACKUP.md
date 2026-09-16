# Qify Authenticator - Final Optional Backup Build

This package implements the final UX:

- The app opens without requiring a Google account.
- A new user can choose `I am a new user` and immediately use the authenticator offline.
- An existing user can choose `I have a backup` and sign in with Google to restore the backup belonging to that exact Google/Firebase account.
- Backup can also be enabled later from Settings -> Backup.
- When backup is enabled, local vault changes automatically attempt to sync to Firestore.
- OTP values are generated locally and are never written to Firestore.
- The Home screen does not display live OTP codes; tapping an account opens the code view.
- Local vault data is encrypted using a random 256-bit local key stored in secure storage.
- Cloud backup is encrypted before upload.

## Important cryptographic limitation

The no-recovery-key UX requires the app to derive the cloud encryption key again on a new phone after the user authenticates with the same Firebase/Google account. This implementation derives that cloud key from the Firebase UID plus a random cloud salt.

That means this is an **authenticated encrypted backup**, not end-to-end encryption against Firebase administrators. Firebase access control prevents other normal users from reading another user's backup, but the derivation secret is not independent of the authenticated account identity.

If strict end-to-end secrecy from the cloud provider is required, a user-held recovery secret or another independently transferable secret is unavoidable.

## Install into the existing project

1. Back up your current project.
2. Extract the ZIP over the existing project.
3. Keep your existing `lib/firebase_options.dart` file. Do not replace it with the example file.
4. Keep your existing Android signing configuration and `google-services.json`.
5. Confirm Google Sign-In is enabled in Firebase Authentication.
6. Deploy `firestore.rules`.
7. Run:

```powershell
flutter clean
flutter pub get
flutter analyze
flutter run
```

## Existing Google Sign-In setup

Your existing Firebase/Android Google sign-in configuration remains required. The ZIP intentionally does not replace your project-specific `firebase_options.dart`, `google-services.json`, SHA fingerprints, release keystore, or Android signing files.

## Backup behavior

When backup is OFF, the app is completely local.

When backup is ON, the backup account is stored locally as metadata and the Firebase UID identifies the cloud vault path:

`users/{uid}/vault/main`

Only the encrypted vault is uploaded. The app does not upload a live OTP/countdown value every 30 seconds.
