# V1 Research Log

### Entry 001 — Stateful local merchant demo

- Date: 2026-08-16; baseline: `a56906b736098c50eead1f8e39881d41c5751a54`; scope: replace demo merchant no-op writes with resettable in-memory stores for menu, offers, reviews, stories, photos, profile, hours, wallet top-ups, and QR redemption.
- Isolation: demo adapters remain local and do not write to Firebase, Storage, callable functions, analytics, or payment systems; real venue identifiers retain the production adapters.
- UX: keep the local-payment warning visible, support local-file menu images, and expose a camera-free demo QR path for customer walkthroughs.
- Verification: `flutter analyze --no-pub` completed with no issues; `flutter test --no-pub` passed 499/499; Samsung SM-A736B device walkthrough covered merchant dashboard, wallet notice, live camera preview, demo token validation, and successful local redemption.

### Entry 002 — Demo handoff integration with current main

- Date: 2026-08-20; baseline: `cb098216cbb8e0fe890ea222f3e5ec5b9c41724d`; source: `5c0811aa2727677bb77efd86d347a5495108f4be`; scope: integrate the production-ready local demo while preserving current admin, security, routing, menu analytics, and wallet-reversal behavior.
- Merge: retained deterministic protected-route authentication, compact navigation and filter reset, merchant wallet reversal review, featured menu previews and analytics, plus the corrected RTL category navigation and one-shot tap-to-expand contract.
- Isolation: demo venue and merchant mutations remain process-local; demo reads and interactions do not reach Firebase, Storage, callable functions, analytics, payment systems, external launchers, sharing, or location services.
- Verification: `flutter test --no-pub` passed 601/601; the responsive matrix passed 65/65; Functions passed 68/68; Admin Web passed 747/747; `flutter analyze --no-pub` and both Git diff checks completed without issues; no deploy or production write was performed.

### Entry 003 — Repair Admin Web CI root paths

- Date: 2026-08-20; baseline: `cc7c839efdb2bbb6406cf6d6d63492125e785620`; scope: repair the Admin Web GitHub Actions gate after the repository root changed from a parent workspace to the Flutter application itself.
- Root cause: `actions/setup-node` could not resolve `wain_app/admin_web_console/package-lock.json`, so the job failed before dependency installation or any security test; the working directory carried the same stale prefix.
- Change: point the Admin Web working directory and npm cache dependency path directly at `admin_web_console` while preserving all security, secure-build, and release-checklist gates.
- Verification: both corrected paths resolve in the checked-out repository; the local Admin Web suite passed 747/747 before the workflow-only change; no deploy or production write was performed.

### Entry 004 — Pin Flutter CI and await guarded Futures

- Date: 2026-08-20; baseline: `6605394c14d5969699f4bc8d10c684f6f48da220`; scope: remove CI drift after the moving `stable` channel advanced beyond the repository's tested Flutter toolchain.
- Root cause: GitHub selected Flutter 3.47.1 while the release and local verification use Flutter 3.38.9, introducing three post-3.41 deprecation diagnostics; the newer analyzer also exposed two Futures returned without `await` inside `try` blocks.
- Change: pin `subosito/flutter-action` to Flutter 3.38.9 and await the guarded Storage URL and menu-import enqueue Futures so their asynchronous failures remain inside the intended fallback handling.
- Verification: focused analysis and tests pass on the pinned local toolchain; no deprecated API suppression, deploy, or production write was introduced.
