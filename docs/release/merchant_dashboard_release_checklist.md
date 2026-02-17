# Merchant Dashboard Release Checklist

This checklist is for releasing the merchant dashboard delta scope:
- Analytics pipeline (`trackVenueEvent`, `aggregateVenueAnalytics`, daily + summary docs)
- Offer counters (`claims_count`, `redeemed_count`, `conversion_rate`, `last_redeemed_at`)
- Merchant notifications routing/types (`offer_redeemed`, `welcome`)
- Merchant dashboard/offers UI updates

## 1. Preflight

- Confirm clean build state and dependencies:
```bash
flutter pub get
```

- Confirm Firebase CLI is available:
```bash
firebase --version
```

- Confirm project context:
```bash
cat .firebaserc
```

## 2. Required Validation (Go/No-Go Gate)

Run from `wain_app`:
```bash
flutter analyze lib/features/merchant lib/features/notifications lib/features/venue/presentation/screens/venue_details_screen.dart lib/features/stories/presentation/screens/story_viewer_screen.dart lib/core/services/analytics_service.dart lib/core/routing/app_router.dart
```

```bash
flutter test test/features/merchant/merchant_analytics_wow_test.dart test/features/notifications/presentation/notification_screen_test.dart test/features/merchant/presentation/screens/merchant_offers_screen_test.dart test/features/merchant/presentation/screens/merchant_dashboard_screen_test.dart
```

Run from `wain_app/functions`:
```bash
npm run build
npm test
npm run test:emulator:aggregate
```

Go only if all commands pass.

## 3. Firestore Security and Indexes

Verify files before deploy:
- `firestore.rules`
- `firestore.indexes.json`

Deploy from `wain_app`:
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

## 4. Functions Deploy

Deploy from `wain_app`:
```bash
firebase deploy --only functions
```

After deploy, verify logs:
```bash
firebase functions:log
```

## 5. Post-Deploy Smoke (Manual)

In production/staging app:
1. Open a venue details page -> triggers `view`.
2. Tap call action -> triggers `call`.
3. View a story -> triggers `story_view`.
4. Claim offer token.
5. Redeem token as merchant.
6. Confirm offer counters updated on `offers/{offerId}`.
7. Confirm merchant notification created with type `offer_redeemed`.
8. Wait for scheduler window (or run backfill callable for merchant) and verify:
   - `venue_analytics/{venueId}`
   - `venue_analytics_daily/{venueId}/days/{dateKey}`
9. Open merchant dashboard and confirm trends/cards load without crash.

## 6. Rollback Guidance

If release is unstable:
1. Stop rollout of app build.
2. Re-deploy previous stable Functions version.
3. Re-deploy previous `firestore.rules` if access regression occurred.
4. Keep analytics writes blocked from client at all times.
5. Re-run emulator tests before the next deploy attempt.

## 7. Release Notes Template

Use this short template:

```text
Release: Merchant Dashboard Delta
Date:
Included:
- Analytics pipeline and daily aggregation
- Offer counters and conversion metrics
- Notification types (offer_redeemed, welcome) with routing
- Dashboard/offers UI trends and badges
Validation:
- flutter analyze: PASS
- flutter tests: PASS
- functions build/unit: PASS
- functions emulator integration: PASS
Known limitations:
- Historical backfill limited to 30 days (callable-assisted)
```
