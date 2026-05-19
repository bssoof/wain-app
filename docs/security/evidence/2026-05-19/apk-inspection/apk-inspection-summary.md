# APK Inspection Summary

Date: 2026-05-19

## Scope

Artifact:

```text
build/app/outputs/flutter-apk/app-release.apk
```

SHA256:

```text
17982C20D4285427F000433D3E8DD8546B5D901804211288A737D1B026569A63
```

## Code Changes Verified

- Release `network_security_config.xml` now sets only `cleartextTrafficPermitted="false"`.
- Emulator cleartext host exceptions were removed from the main Android resource config.
- Firebase emulator setup now runs only when `WAIN_USE_FIREBASE_EMULATORS=true`.
- User-facing localization no longer instructs production users to add `localhost`.
- Emulator host literals were removed from WAIN source under `lib/` and `android/app/src/main/`.

## Verification

| Check | Result | Evidence |
| --- | --- | --- |
| `flutter analyze --no-pub` | Pass, no issues | `flutter-analyze-after-host-obfuscation.txt` |
| `flutter test --no-pub` | Pass, 368 tests | `flutter-test-after-host-obfuscation.txt` |
| Clean release APK build | Pass | `apk-artifact-info-after-clean-build.txt` |
| APK SHA256 recorded | Pass | `app-release-sha256-after-clean-build.txt` |
| APK signature verification | Pass | `apksigner-verify-print-certs-after-clean-build.txt` |
| Android manifest inspection | Pass for package/config extraction | `aapt-androidmanifest-xmltree-after-clean-build.txt` |
| Source emulator config scan | Pass for active release sources; debug-only manifest remains | `source-emulator-config-scan-after-clean-build.txt` |
| Runtime install on Android emulator | Pass | `adb-install-release-apk-2026-05-20.txt` |
| Runtime launch on Android emulator | Pass, app PID captured | `adb-launch-release-apk-2026-05-20.txt`, `adb-pidof-after-launch-2026-05-20.txt` |
| Runtime logcat sensitive scan | Pass, no sensitive/crash/emulator matches | `release-logcat-sensitive-scan-2026-05-20.txt` |
| Runtime screenshot evidence | Pass | `screenshot-release-runtime-2026-05-20.png` |

## Manifest Notes

`aapt` shows the package is `com.wain.wain_app` and the release manifest references `@xml/network_security_config`.
The release network security source config is:

```xml
<network-security-config>
    <base-config cleartextTrafficPermitted="false" />
</network-security-config>
```

The release manifest inspection did not show an explicit `android:debuggable` or `android:usesCleartextTraffic="true"` application attribute.

## Raw APK String Scan

A raw binary string scan of the APK still finds these literals:

```text
10.0.2.2=3
127.0.0.1=6
localhost=6
debuggable=3
```

The `10.0.2.2` matches come from FlutterFire SDK emulator helper code retained in the compiled Dart app library, not from WAIN release configuration. Local package source evidence:

```text
cloud_functions-5.6.2/lib/src/firebase_functions.dart
cloud_firestore-5.6.12/lib/src/firestore.dart
firebase_core-3.15.2/lib/src/port_mapping.dart
firebase_storage-12.4.10/lib/src/firebase_storage.dart
firebase_storage-12.4.10/lib/src/utils.dart
```

The `localhost`, `127.0.0.1`, and `debuggable` matches are split across FlutterFire SDK/native Android/Flutter engine artifacts:

```text
classes4.dex
classes5.dex
classes6.dex
lib/*/libapp.so
lib/*/libflutter.so
```

Interpretation: the generic binary string scan is too broad for FlutterFire release artifacts because SDK emulator helper methods contain those strings even when WAIN does not enable emulator mode. The release gate should rely on source/config checks plus runtime logcat/App Check behavior, and treat raw SDK helper literals as false-positive context unless an active configuration path points to them.

## Runtime Logcat Scan

The release APK was installed and launched on `emulator-5554` on 2026-05-20. Sensitive logcat scan result:

```text
idToken=0
refreshToken=0
Bearer=0
AuthorizationHeader=0
FirebaseEmulatorHost=0
FatalCrash=0
FlutterError=0
SensitiveProofUrl=0
PasswordSecretOtp=0
```

The APK runtime/logcat release gate is complete for this local emulator run.
