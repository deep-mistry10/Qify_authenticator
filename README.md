# Qify Authenticator

> A privacy-focused, offline-first TOTP authenticator built with Flutter.

Qify Authenticator is a planned cross-platform authenticator application designed around one core principle:

**Your OTP secrets should remain protected locally, while encrypted vault data can be synchronized for recovery across devices.**

The first target platform is **Android**, built with **Flutter and Android Studio**. Windows, Linux, and macOS support are planned for later stages.

> **Project status: DEVELOPMENT — NOT FINISHED**
>
> Qify Authenticator is currently in the development phase and is **not a finished or production-ready application**. Features described below are part of the planned architecture and roadmap unless they are explicitly marked as implemented. APIs, UI, security implementation, cryptographic parameters, synchronization behavior, and project structure may change during development.

---

## Development Status

**Current stage: Development / Not Finished**

Qify Authenticator is actively being built and is **not yet complete**.

At this stage:

- The project architecture and security model are being developed.
- Planned features may not yet be implemented.
- Implemented features may change or be replaced during development.
- Security-sensitive functionality requires testing and review before production use.
- Android is the first target platform; desktop platforms are planned for later.
- A stable production release has **not** been reached.

Do not treat the current development build as a final authenticator for critical accounts.

---

## Overview

Qify Authenticator is intended to provide the core functionality of apps such as Google Authenticator and Microsoft Authenticator while using an **offline-first architecture**.

The application will:

- Generate TOTP codes locally without requiring an internet connection.
- Store authenticator secrets inside an encrypted local vault.
- Support QR-code and manual TOTP account setup.
- Protect the app with biometric authentication and a PIN fallback.
- Use Firebase Authentication for account identity.
- Use Firebase Firestore only to store **encrypted vault data and metadata** for synchronization and recovery.
- Allow a user to restore their encrypted vault on another device after signing into the same account.

### Core Security Principle

**Firebase must never receive generated OTP codes, plaintext TOTP secrets, vault passwords, or plaintext vault contents.**

The OTP engine works locally on the user's device.

---

# Features

## Authentication

The planned authentication system includes:

- Account registration
- Login
- Logout
- Password reset
- Firebase Authentication integration
- Authenticated user-specific cloud storage

Firebase Authentication is used for account identity and access control, not for generating or storing OTP codes.

---

## TOTP Accounts

Version 1 is focused on standard TOTP authentication.

Planned account features:

- Add account using QR code
- Add account manually
- Parse `otpauth://` URIs
- Generate 6-digit OTP codes
- 30-second default OTP period
- SHA-1 support for the initial TOTP implementation
- Live countdown until code refresh
- Copy OTP code
- Search accounts
- Edit account
- Delete account
- Reorder accounts
- Account details screen

Later versions may add:

- SHA-256
- SHA-512
- 8-digit codes
- Custom OTP periods
- HOTP support

---

# Security Architecture

Security is the most important part of the project.

The application is designed so that sensitive authentication data remains protected even when cloud synchronization is enabled.

## Data Separation

| Data | Local Device | Firebase |
|---|---:|---:|
| Generated OTP | Yes | Never |
| TOTP secret in plaintext | Yes, temporarily inside protected local processes | Never |
| Encrypted vault | Yes | Yes |
| Vault password | Never uploaded | Never |
| Vault Master Key | Protected locally | Never stored directly |
| Firebase account identity | Yes | Yes |
| Non-sensitive synchronization metadata | Yes | Yes |

### Important Rule

The server should never need to know the current six-digit OTP.

OTP generation is performed entirely on the user's device.

---

# Encrypted Vault Design

Qify Authenticator uses an encrypted vault model.

The planned architecture is based on a randomly generated **Vault Master Key (VMK)**.

A simplified flow is:

```text
User Vault Password / Recovery Credential
                 |
                 v
              KDF
                 |
                 v
        Key Encryption Key
                 |
                 v
          Wrapped VMK
                 |
                 v
       Encrypted Vault Data
```

The VMK is used to protect the vault.

The exact cryptographic algorithms, parameters, and implementation details will be finalized using maintained and reviewed cryptographic libraries rather than implementing custom cryptography.

### Security Requirements

The application must never upload:

- Generated OTP codes
- Plaintext TOTP secrets
- Vault passwords
- Recovery secrets
- Raw encryption keys
- Plaintext vault contents

The cloud service should only contain encrypted vault data and permitted metadata.

---

# Cloud Synchronization

Firebase is used as a synchronization and recovery layer.

The local vault remains the **primary source of truth** for normal operation.

A planned Firestore document structure is:

```text
/users/{uid}/vault/main
```

The cloud vault will contain encrypted content and synchronization metadata.

It must not contain plaintext authenticator secrets.

## Sync Model

The intended flow is:

```text
Local Vault
    |
    | Encrypt
    v
Encrypted Vault
    |
    | Upload
    v
Firebase Firestore
    |
    | Download
    v
Encrypted Vault
    |
    | Decrypt locally
    v
Local Vault
```

Cloud synchronization is separate from OTP generation.

The app should remain usable when the network is unavailable.

---

# Offline-First Design

Qify Authenticator is designed to work offline for normal authenticator usage.

After the vault has been created and unlocked, the following operations should work without internet access:

- Viewing authenticator accounts
- Generating TOTP codes
- Refreshing OTP codes
- Copying OTP codes
- Searching accounts
- Editing local account information
- Reordering accounts
- Deleting accounts
- Using the application lock

Internet access is primarily required for features such as:

- Firebase authentication
- Cloud synchronization
- Vault recovery on a new device
- Uploading encrypted vault changes

The local encrypted vault remains the main operational data source.

---

# Cross-Device Recovery

One of the main goals of Qify Authenticator is secure recovery when a device is lost or replaced.

A planned recovery flow is:

```text
New Device
    |
    v
Install Qify Authenticator
    |
    v
Sign in with the same Firebase account
    |
    v
Download encrypted vault
    |
    v
Enter vault password / recovery credential
    |
    v
Decrypt vault locally
    |
    v
Restore authenticator accounts
```

The cloud should only provide encrypted vault data.

The new device performs decryption locally.

---

# App Lock

The planned application protection system includes:

- Biometric authentication
- PIN fallback
- Automatic lock after inactivity
- Lock when the application returns from the background
- Protection against exposing vault information while the application is locked

The exact lock policies may evolve during implementation and testing.

---

# QR Code and Manual Setup

Qify Authenticator will support standard TOTP provisioning through:

### QR Code

Users can scan a TOTP QR code and import supported `otpauth://` information.

### Manual Entry

Users will also be able to enter account information manually.

The application should validate the imported data and reject malformed or unsupported provisioning information rather than silently accepting invalid values.

---

# TOTP Engine

The initial TOTP implementation targets:

- SHA-1
- 6-digit codes
- 30-second period
- Standard `otpauth://` provisioning

The basic concept is:

```text
Shared Secret
      +
Current Unix Time
      |
      v
   Counter
      |
      v
   HMAC
      |
      v
Dynamic Truncation
      |
      v
  Numeric OTP
```

The OTP is calculated locally on the device.

Future versions may expand support to additional algorithms, digit lengths, periods, and HOTP.

---

# Project Architecture

The planned Flutter project structure follows separation of concerns.

A simplified structure is:

```text
lib/
├── core/
│   ├── security/
│   ├── crypto/
│   ├── storage/
│   ├── network/
│   └── utils/
│
├── features/
│   ├── authentication/
│   ├── vault/
│   ├── totp/
│   ├── backup/
│   ├── settings/
│   └── lock/
│
├── data/
│   ├── models/
│   ├── repositories/
│   └── services/
│
├── presentation/
│   ├── screens/
│   ├── widgets/
│   └── theme/
│
└── main.dart
```

The exact directory layout may change as implementation progresses, but the architecture should continue to keep authentication, vault storage, encryption, TOTP generation, synchronization, and presentation logically separated.

---

# Planned Screens

The application is planned to include the following screens:

1. Splash Screen
2. Login
3. Register
4. Password Reset
5. Vault Setup
6. Home / Authenticator Vault
7. Add Account
8. QR Scanner
9. Manual Account Entry
10. Account Details
11. Settings
12. App Lock
13. Backup & Recovery
14. About

---

# Technology Stack

| Component | Technology |
|---|---|
| UI / Application | Flutter |
| Language | Dart |
| First Platform | Android |
| Development IDE | Android Studio |
| Authentication | Firebase Authentication |
| Cloud Storage / Sync | Firebase Firestore |
| OTP Generation | Local TOTP engine |
| Local Secure Storage | Platform-protected secure storage |
| Encryption | Maintained cryptographic libraries |
| QR Provisioning | TOTP `otpauth://` QR flow |

---

# Development Roadmap

> **All roadmap phases are part of an ongoing development plan. Completion of a phase does not mean the entire project is finished or production-ready.**

## Phase 1 — Project Foundation

- Create Flutter project
- Configure Android project
- Configure Firebase
- Set up application architecture
- Create authentication screens
- Create initial home shell

## Phase 2 — Authentication

- Registration
- Login
- Logout
- Password reset
- Authentication state handling

## Phase 3 — TOTP Engine

- TOTP implementation
- `otpauth://` parsing
- SHA-1 support
- 6-digit codes
- 30-second period
- Countdown and refresh logic

## Phase 4 — Vault

- Local vault model
- Secure local storage
- Add/edit/delete accounts
- Search
- Reordering
- Account details

## Phase 5 — Encryption

- VMK creation
- Key derivation
- VMK wrapping
- Authenticated encryption
- Secure unlock and decrypt flow

## Phase 6 — App Security

- Biometric unlock
- PIN fallback
- Automatic locking
- Background protection
- Sensitive-data handling review

## Phase 7 — Cloud Sync

- Encrypted vault upload
- Encrypted vault download
- Firestore security rules
- Synchronization metadata
- Conflict handling
- Recovery flow

## Phase 8 — Testing

- Unit tests
- Widget tests
- Integration tests
- Security-focused tests
- TOTP test vectors
- Malformed QR tests
- Offline tests
- Recovery tests

## Phase 9 — Android Release

- Production build
- Security review
- Performance testing
- Release configuration
- Documentation
- Android release

## Phase 10 — Desktop Expansion

After Android reaches a stable release, support for:

- Windows
- Linux
- macOS

may be added.

---

# Conflict Handling

Cloud synchronization must not silently destroy newer vault data.

The application should detect synchronization conflicts and use an explicit strategy rather than blindly replacing local data.

Potential conflict information may include:

- Vault revision
- Updated timestamp
- Device metadata
- Synchronization state

The exact conflict-resolution mechanism will be finalized during implementation and testing.

---

# Testing Strategy

Security-sensitive software requires testing at multiple levels.

## Unit Tests

Planned unit testing includes:

- TOTP calculations
- URI parsing
- Validation
- Encryption/decryption logic
- Key derivation flow
- Vault serialization
- Synchronization logic

## Widget Tests

Planned widget tests include:

- Authentication screens
- Vault screens
- Add account flow
- Account details
- Lock screen
- Settings

## Integration Tests

Planned integration testing includes:

- Login and authentication
- Create vault
- Add TOTP account
- Generate OTP
- Lock and unlock application
- Cloud backup
- Cloud restore
- Cross-device recovery
- Offline operation
- Conflict scenarios

## Security Testing

Special attention will be given to:

- Preventing secrets from entering logs
- Preventing OTP values from being uploaded
- Preventing plaintext vault uploads
- Firestore ownership enforcement
- Malformed QR handling
- Encryption/decryption failures
- Locked-state protection
- Recovery validation

---

# Sensitive Data Handling

The following information must never be written to debug logs, analytics, or cloud documents in plaintext:

- TOTP secrets
- Generated OTP codes
- Vault passwords
- Recovery credentials
- Encryption keys
- Plaintext vault contents

Development logging should be treated as security-sensitive.

---

# Version 1 Scope

The first stable Android version is intentionally limited to the core authenticator experience.

### Included

- Firebase authentication
- TOTP accounts
- QR setup
- Manual TOTP setup
- Local encrypted vault
- Offline OTP generation
- App lock
- Biometric authentication
- PIN fallback
- Encrypted cloud synchronization
- Recovery on another device
- Security and integration testing

### Excluded from Version 1

The following are outside the initial scope:

- Password manager
- SMS authentication
- Push authentication
- Enterprise/team vault sharing
- Browser extension
- Browser autofill
- Custom cryptographic algorithms
- Desktop release before Android stabilization

These features may be considered in later versions.

---

# Privacy

Qify Authenticator is designed around minimizing sensitive cloud exposure.

The planned architecture separates:

**Authentication**

Firebase identifies the user.

**Vault**

Encrypted local storage protects authenticator data.

**Synchronization**

Firebase stores encrypted vault data for recovery and synchronization.

**OTP Generation**

OTP codes are generated locally on the device.

The goal is that the cloud service never needs access to the user's plaintext authenticator secrets or current OTP codes.

---

# Local Development

Clone the repository and verify your Flutter environment:

```bash
flutter doctor
```

Create a Flutter project during initial setup:

```bash
flutter create qify_authenticator
```

Run the application:

```bash
flutter run
```

Before working on Firebase functionality, configure the Firebase project and connect the Flutter application according to the project's Firebase setup.

---

# Repository Structure

A recommended public repository structure is:

```text
qify_authenticator/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
├── .gitignore
├── pubspec.yaml
├── lib/
├── test/
└── integration_test/
```

Additional directories and configuration files may be added as implementation progresses.

---

# Security Reporting

Security issues should be handled responsibly.

Do not publicly post sensitive exploit details, credentials, OTP secrets, encryption keys, or private user data in GitHub issues.

A dedicated security-reporting process should be added before the first public production release.

---

# License

The project license will be added before the first public release.

Until a license is explicitly included in the repository, the source code should not be assumed to be freely reusable, modified, or redistributed.

---

# Disclaimer

Qify Authenticator is an independent project.

It is **not affiliated with, endorsed by, or sponsored by Google, Microsoft, or other authenticator providers**.

This project is under development and may not yet have completed security auditing or production validation.

Do not rely on an unreleased or unaudited build as the only means of accessing critical accounts.

---

# Project Goal

The long-term goal of Qify Authenticator is to provide a practical authenticator that combines:

- Local-first OTP generation
- Strong encrypted vault protection
- Offline usability
- Secure cloud recovery
- Cross-device restoration
- Clear separation between authentication, synchronization, and secret processing

The central design principle is simple:

> **The cloud may store encrypted recovery data, but OTP generation and secret access remain local to the user's device.**

---

## Development Status

**Qify Authenticator is currently under development and is not finished.**

This repository represents an evolving project. The application has not reached its final production-ready state.

Architecture, implementation details, cryptographic parameters, synchronization behavior, supported platforms, UI, and feature scope may change as development, testing, and security review progress.

Roadmap items should be considered planned work unless the repository explicitly marks them as implemented.

For the latest implementation status, refer to the project's commits, issues, roadmap, and release notes.
