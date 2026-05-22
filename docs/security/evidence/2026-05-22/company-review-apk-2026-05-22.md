# Company Review APK Evidence

Date: 2026-05-22
Scope: Android company review APK

## Artifact

```text
build/company-review/wain-android-company-review-2026-05-22.apk
```

This APK is a sideload/company-review artifact so the company can inspect the current Android work while Google Play Console account verification is still pending.

This is not the final production Play release artifact and must not be used as App Check Play Integrity enforcement proof.

## Build Command

```powershell
& "C:\src\flutter_windows_3.38.9-stable\flutter\bin\flutter.bat" build apk --release
```

Result:

```text
Built build\app\outputs\flutter-apk\app-release.apk (93.8MB)
```

## Artifact Digest

```text
SHA256: 17982C20D4285427F000433D3E8DD8546B5D901804211288A737D1B026569A63
Git commit: 7cf1fce422d4d35e74559632d1865b422ae046d3
Size: 98,390,589 bytes
```

The same digest was written to:

```text
build/company-review/wain-android-company-review-2026-05-22.sha256.txt
```

## Signature Verification

Command:

```powershell
& "C:\Users\a-z\AppData\Local\Android\Sdk\build-tools\36.1.0\apksigner.bat" verify --print-certs build\company-review\wain-android-company-review-2026-05-22.apk
```

Result:

```text
Signer #1 certificate DN: CN=Wain App, OU=Engineering, O=Wain, L=Ramallah, ST=Palestine, C=PS
Signer #1 certificate SHA-256 digest: ed673a2a3337786d31b2d6c7a23e71838fdbc430151e665853892d4a3df7cc8f
Signer #1 certificate SHA-1 digest: c3231a4a3a73b661f944fef544261ba019cdb9e1
```

The signing certificate matches the Firebase Android App Check fingerprint evidence captured earlier.

## App Check Caveat

Because this APK is installed outside Google Play, Firebase App Check / Play Integrity metrics may show invalid or unverified requests. Do not enable App Check enforcement based on this sideload APK.

Final App Check validation still requires:

1. Completing Play Console developer account verification.
2. Uploading the release artifact to Google Play Internal Testing.
3. Installing the app from Google Play.
4. Repeating the Storage/Firestore/Auth/Functions smoke tests.
5. Confirming App Check metrics are verified before enforcing.
