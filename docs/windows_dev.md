# Windows Development Notes

## Purpose
Windows is treated as a local development target for UI/debug workflows. It is not production-parity with mobile for every Firebase plugin.

## Runtime Policy on Windows
- App startup must continue even if Firebase init fails.
- Firebase App Check is intentionally skipped on Windows.
- Firebase Messaging is intentionally skipped on Windows.
- Missing plugin exceptions from App Check/Messaging must not appear during startup.

## Firebase Plugin Support Matrix (This Project)
| Plugin | Windows Policy | Notes |
|---|---|---|
| `firebase_core` | Required | App initializes with `DefaultFirebaseOptions.currentPlatform`. |
| `firebase_auth` | Used | Must pass smoke login/logout checks. |
| `cloud_firestore` | Used | Must pass read/write smoke checks or fail gracefully in UI. |
| `firebase_storage` | Used | Used by media/menu flows; validate in smoke if touched. |
| `cloud_functions` | Used | Used in multiple feature flows; failures should show UI errors, not crash app. |
| `firebase_app_check` | Disabled by design | Skipped on Windows startup. |
| `firebase_messaging` | Disabled by design | No listener/background registration/getInitialMessage on Windows. |
| `firebase_analytics` | Non-blocking | Analytics calls are best-effort and should not crash app. |
| `firebase_crashlytics` | Non-critical on startup | Not part of startup-critical path. |

## Expected Console Warnings
- `LNK4099` warnings from Firebase C++ libraries can appear on Windows debug builds and are non-fatal.
- CMake deprecation warnings can appear and are non-fatal.

## Troubleshooting
1. If app fails before UI appears, run:
   - `flutter clean`
   - `flutter pub get`
   - `flutter run -d windows`
2. If Firebase startup fails, app should still launch and show a warning banner.
3. If you see `MissingPluginException` for App Check or Messaging on Windows, this is a regression and must be fixed before merge.
