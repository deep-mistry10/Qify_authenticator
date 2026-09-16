# Qify Authenticator

Offline-first TOTP authenticator with optional encrypted Google-account cloud backup.

## Final behavior

The app does not require an account to open.

First launch:

- `I am a new user` -> opens the local authenticator.
- `I have a backup` -> Google Sign-In -> finds the backup for that exact account -> restores it.

Later:

- Settings -> Backup -> turn cloud backup on.
- Choose the Google account used for the backup.
- Existing local accounts are backed up.
- Later account additions/deletions automatically attempt backup synchronization.

The TOTP codes themselves are generated locally.
