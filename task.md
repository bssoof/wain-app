# مهام تنفيذ رصيد وين (WAIN Credit)

- `[x]` **## Phase 0: Foundations & Architecture
- [ ] Create `Firestore` security rules for `merchant_wallets`, `merchant_wallets/*/entries`, and `merchant_topup_requests`.
- [x] Ensure `merchant_wallets` can only be read by the venue owner, and written strictly by Cloud Functions.
- [ ] Ensure `merchant_topup_requests` can be read by venue owner, and created with `status: pending`.

## Phase 1: WAIN Credit Wallet & Top-Up Flow (The End-to-End Foundation)
- [x] Create `MerchantWallet` and `MerchantTopUpRequest` domain entities.
- [ ] Implement `MerchantWalletRepository` to stream wallet state and request history.
- [ ] Develop a Cloud Function `createMerchantTopUpRequest` (handles idempotency and secure creation).
- [ ] Create `MerchantWalletScreen` UI.
- [ ] Inject a `Wallet Summary Card` into the main `MerchantDashboardScreen` to immediately show balance.
- [ ] Create `reviewMerchantTopUpRequest` (Admin Function) to test and simulate approving requests securely.

## Phase 1 Hardening: Compile Fix + Rules Lockdown + Test Coverage
- [x] Fix Flutter compilation errors (imports, design system elements, providers).
- [x] Lock down `merchant_topup_requests` in `firestore.rules` to prevent client direct creation.
- [x] Remove side-effects (e.g., `logSecurityAudit`) from transaction callbacks in Cloud Functions.
- [x] Add emulator tests for Cloud Functions.
- [x] Add Firebase Rules emulator tests.
- [x] Add basic widget tests for the new wallet UI.
- [ ] Align admin path in `reviewMerchantTopUpRequest` with existing roles setup (Deferred to actual Admin implementation round).
- [ ] Add receipt photo upload functionality to the top-up sheet (Deferred).

**قاعدة دقة إلزامية:**
لا تُعتبر أي جولة منتهية قبل:
1. تشغيل build / analyze / tests الفعلية على التغييرات.
2. توثيق الأوامر التي شُغّلت ونتائجها بدقة.
3. التأكد أن السلوك المعلن موجود فعلاً في الكود وليس مجرد نية أو قراءة.
4. منع أي bypass أمني أو direct client write في المسارات المالية.
5. ذكر ما لم يُختبر بوضوح وصراحة.

- `[x]` **Phase 2: Story Promotion Integration (الربط بخصم الستوري)**
  - `[x]` تعديل `promoteStory` Function للخصم من الرصيد داخل Transaction.
  - `[x]` عرض تكلفة الترويج في واجهة القصص.
  - `[x]` معالجة حالة الرصيد غير الكافي (Insufficient Balance).

- `[ ]` **Phase 3: Wallet UX And Hardening (تحسين التجربة العُليا)**
  - `[ ]` لوحة مُلخص الرصيد للتاجر (Wallet Dashboard Card)
  - `[ ]` شاشة سجل الحركات المالية (Transaction History Screen)
  - `[ ]` تنبيه نقص الرصيد (Low-balance Banner)
