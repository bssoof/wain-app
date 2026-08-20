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
