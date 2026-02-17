# Merchant Experience Walkthrough - Phase 3 (COULD)

## Phase 2: Core Merchant Features (Completed)

- **Edit Venue**: Can update name, description, category, and city.
- **Manage Photos**: Upload, Order, Delete photos.
- **Reviews**: View user reviews, Reply to them, Delete replies.
- **Stories**: Add/Delete stories, View active stories.
- **Offers**: List offers, Toggle active status.

### Verification

- [x] Edit Venue: Updates reflected in Firestore.
- [x] Photos: Storage interaction works (mocked/real).
- [x] Reviews: Reply/Delete UI functional.
- [x] Offers: Switch toggle updates Firestore (deprecated `activeColor` fixed).

---

## Phase 3: Notifications & Scanner (Completed)

### 1. Notification Center 🔔

- **Location**: Top of Merchant Dashboard (Bell Icon).
- **Features**:
  - Badge showing unread count.
  - List of notifications (Reviews, Offers, System).
  - Mark as read functionality.
  - "Mark All Read" button.

### 2. QR Redemption System 📷

- **Location**: "ماسح الكود" Button in Dashboard Quick Actions.
- **Security**:
  - ✅ Merchant must own the venue to validate/redeem offers
  - ✅ Cross-venue scanning blocked (e.g., Stono cannot scan Vanilla's offers)
- **Features**:
  - **Scanner**: Uses camera to scan User QR codes.
  - **Validation**: Calls `validateToken` Cloud Function (with ownership check).
  - **Result Sheet**: Shows Offer/Venue details and "Redeem" button.
  - **Redemption**: Calls `redeemToken` Cloud Function (with ownership verification).

### Manual Testing Steps

1.  **Notifications**:
    - Click the Bell Icon.
    - Verify the list loads.
    - Tap an item -> Should mark as read (icon changes).
2.  **QR Scanner (Same Venue)**:
    - Click "ماسح الكود".
    - Accept Camera Permission.
    - Scan a QR code from User App (same venue) -> See Result Sheet.
    - Click "Redeem" -> See Success message.

3.  **QR Scanner (Cross-Venue) - Security Test**:
    - Login as merchant for Venue A (e.g., Stono)
    - Scan QR code for offer from Venue B (e.g., Vanilla)
    - Should see error: "This offer belongs to a different venue"

---

## Security Updates (Post-Deployment)

### Critical Fix: QR Cross-Venue Validation

- **Issue**: Any merchant could view offers from other venues
- **Fix**: Added `venue_id` ownership check in `validateToken`
- **Status**: Deployed to Cloud Functions
