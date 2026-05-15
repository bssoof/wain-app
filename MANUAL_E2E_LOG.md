# Merchant Reversal Manual E2E Log

Generated: 2026-05-13T23:35:49.853Z

> هذه الجولة شغّلت gate آلي على Auth/Firestore emulators باستخدام نفس callables والـ state transitions. الفحص البصري داخل Flutter/Admin UI يبقى خطوة يدوية لاحقة على نفس seed.

[x] السيناريو 1: direct execute <= 100 ILS — PASS
    - balance قبل: 800, بعد: 850
    - request status: approved_and_executed
    - reversal entry id: reversal_entry_test_50
[x] السيناريو 2: pending_second_approval > 100 ILS — PASS
    - required role: finance_admin
    - same-admin approval blocked: second_approver_must_differ
    - executed reversal: reversal_entry_test_150
[x] السيناريو 3: الرفض — PASS
    - balance unchanged: 1000
    - request status: rejected
[x] السيناريو 4: حالات الحافة — PASS
    - credit entry blocked
    - unsupported feature blocked
    - already reversed entry blocked
[x] السيناريو 5: race condition — PASS
    - direct reversal status: reversed
    - merchant request approve blocked: entry_already_reversed
    - request final status: rejected
