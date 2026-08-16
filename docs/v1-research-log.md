# V1 Research Log

### Entry 001 — Stateful local merchant demo

- Date: 2026-08-16; baseline: `a56906b736098c50eead1f8e39881d41c5751a54`; scope: replace demo merchant no-op writes with resettable in-memory stores for menu, offers, reviews, stories, photos, profile, hours, wallet top-ups, and QR redemption.
- Isolation: demo adapters remain local and do not write to Firebase, Storage, callable functions, analytics, or payment systems; real venue identifiers retain the production adapters.
- UX: keep the local-payment warning visible, support local-file menu images, and expose a camera-free demo QR path for customer walkthroughs.
- Verification: `flutter analyze --no-pub` completed with no issues; `flutter test --no-pub` passed 499/499; Samsung SM-A736B device walkthrough covered merchant dashboard, wallet notice, live camera preview, demo token validation, and successful local redemption.
