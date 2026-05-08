import { describe, expect, it } from "vitest";

import {
  localizeAdminFreshnessNote,
  localizeAdminLabel,
  localizeAdminMessage,
} from "@/lib/admin/admin-localization";

describe("admin localization", () => {
  it("hides implementation source names behind simple Arabic labels", () => {
    expect(localizeAdminLabel("callable:listOffersForAdmin")).toBe("الخدمة المتصلة");
    expect(localizeAdminLabel("http:https://example.test/read")).toBe(
      "اتصال مباشر بالخدمة",
    );
    expect(localizeAdminLabel("firestore:admin_finance")).toBe("قاعدة البيانات");
  });

  it("uses plain Arabic for technical command and transport failures", () => {
    expect(localizeAdminMessage("Offer moderation transport is unavailable.")).toBe(
      "الاتصال بالخدمة غير متاح.",
    );
    expect(
      localizeAdminMessage("Action is not mapped to a callable surface yet."),
    ).toBe("لا توجد خدمة مربوطة لهذا الإجراء بعد.");
    expect(localizeAdminMessage("venue_expected_state_required")).toBe(
      "الطلب يحتاج بيانات الحالة الحالية كاملة قبل تنفيذ التعديل.",
    );
    expect(localizeAdminMessage("venue_not_active")).toBe(
      "لا يمكن تنفيذ العملية لأن حالة الجهة ليست نشطة.",
    );
    expect(localizeAdminMessage("venue_expected_state_conflict")).toBe(
      "تعذر تنفيذ العملية لأن حالة الجهة تغيّرت قبل اعتماد الطلب.",
    );
    expect(
      localizeAdminMessage(
        "NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN is a placeholder and cannot call live Firebase Functions.",
      ),
    ).toBe(
      "توكن أمان الطلب الحالي تجريبي، لذلك لا يمكن تنفيذ القرار على الخدمة الحية.",
    );
  });

  it("localizes fallback notes and runtime summaries to Arabic", () => {
    expect(localizeAdminLabel("content_offers")).toBe("العروض");
    expect(localizeAdminLabel("wallet_audit")).toBe("سجل المحفظة");
    expect(localizeAdminLabel("review_escalate")).toBe("إرسال للمراجعة");
    expect(localizeAdminFreshnessNote("Loaded directly from Firestore.")).toBe(
      "تم تحميل البيانات مباشرة من قاعدة البيانات.",
    );
    expect(localizeAdminMessage("Venue directory callable read failed: timeout")).toBe(
      "تعذر جلب دليل الجهات من الخدمة المتصلة.",
    );
    expect(localizeAdminMessage("No reviews matched the current moderation surface.")).toBe(
      "لا توجد مراجعات مطابقة للعرض الحالي.",
    );
    expect(localizeAdminMessage("review_already_in_target_state")).toBe(
      "المراجعة موجودة أصلًا في الحالة المطلوبة.",
    );
    expect(
      localizeAdminMessage("review_moderation_expected_state_conflict"),
    ).toBe("تعذر تنفيذ القرار لأن حالة المراجعة تغيّرت قبل اعتماد الطلب.");
  });
});
