import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { MerchantReversalRequest } from "@/lib/finance/read-models";

import { MerchantReversalReviewPanel } from "./merchant-reversal-review-panel";

const toastShow = vi.fn();

vi.mock("@/components/shared/ui/toast", () => ({
  useToast: () => ({
    show: toastShow,
    dismiss: vi.fn(),
  }),
}));

function timestamp(iso: string): MerchantReversalRequest["createdAt"] {
  const date = new Date(iso);
  return {
    toDate: () => date,
    toMillis: () => date.getTime(),
  } as MerchantReversalRequest["createdAt"];
}

function makeRequest(
  overrides: Partial<MerchantReversalRequest> = {},
): MerchantReversalRequest {
  return {
    requestId: "merchant_review_entry-001",
    source: "merchant",
    status: "pending_review",
    venueId: "venue_001",
    entryId: "entry_001",
    originalAmount: 120,
    currency: "ILS",
    originalFeatureKey: "story_promotion",
    requestedByUid: "merchant_uid_001",
    reason: "تم خصم الرصيد من ترويج قصة لكن الخدمة لم تكتمل.",
    merchantNote: "أرفقت تفاصيل العملية من شاشة المحفظة.",
    reviewedByUid: null,
    reviewedByRole: null,
    reviewedAt: null,
    adminDecision: null,
    adminNote: null,
    rejectionReason: null,
    requiredSecondApproverRole: null,
    reversalEntryId: null,
    createdAt: timestamp("2026-05-12T08:00:00.000Z"),
    updatedAt: timestamp("2026-05-12T08:00:00.000Z"),
    expiresAt: null,
    ...overrides,
  };
}

function renderPanel(
  overrides: Partial<Parameters<typeof MerchantReversalReviewPanel>[0]> = {},
) {
  const props = {
    requests: [makeRequest()],
    isLoading: false,
    error: null,
    canReview: true,
    onApprove: vi.fn().mockResolvedValue(undefined),
    onReject: vi.fn().mockResolvedValue(undefined),
    onRefresh: vi.fn(),
    ...overrides,
  };

  render(<MerchantReversalReviewPanel {...props} />);
  return props;
}

describe("MerchantReversalReviewPanel", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("shows loading state and hides the table", () => {
    renderPanel({ isLoading: true });

    expect(screen.getByText("جارٍ تحميل الطلبات...")).toBeTruthy();
    expect(screen.queryByTestId("merchant-reversal-review-table")).toBeNull();
  });

  it("shows error banner with retry action", () => {
    const onRefresh = vi.fn();
    renderPanel({ error: "backend unavailable", onRefresh });

    expect(screen.getByRole("alert").textContent).toContain(
      "backend unavailable",
    );
    fireEvent.click(screen.getByRole("button", { name: "إعادة المحاولة" }));
    expect(onRefresh).toHaveBeenCalledTimes(1);
  });

  it("shows empty state when there are no requests", () => {
    renderPanel({ requests: [] });

    expect(
      screen.getByText("لا توجد طلبات مراجعة بانتظار النظر."),
    ).toBeTruthy();
    expect(screen.queryByTestId("merchant-reversal-review-table")).toBeNull();
  });

  it("hides action buttons when admin cannot review", () => {
    renderPanel({ canReview: false });

    expect(screen.getByTestId("merchant-reversal-readonly-banner")).toBeTruthy();
    expect(
      screen.queryByLabelText("اعتماد طلب مراجعة merchant_review_entry-001"),
    ).toBeNull();
    expect(screen.getByText("قراءة فقط")).toBeTruthy();
  });

  it("opens approve modal", () => {
    renderPanel();

    fireEvent.click(
      screen.getByLabelText("اعتماد طلب مراجعة merchant_review_entry-001"),
    );

    expect(screen.getByRole("dialog")).toBeTruthy();
    expect(screen.getByText("اعتماد طلب مراجعة")).toBeTruthy();
  });

  it("opens reject modal", () => {
    renderPanel();

    fireEvent.click(
      screen.getByLabelText("رفض طلب مراجعة merchant_review_entry-001"),
    );

    expect(screen.getByRole("dialog")).toBeTruthy();
    expect(screen.getByText("رفض طلب مراجعة")).toBeTruthy();
  });

  it("keeps reject confirmation disabled while rejection reason is empty", () => {
    renderPanel();

    fireEvent.click(
      screen.getByLabelText("رفض طلب مراجعة merchant_review_entry-001"),
    );

    expect(
      (screen.getByRole("button", {
        name: "تأكيد رفض طلب التاجر",
      }) as HTMLButtonElement).disabled,
    ).toBe(true);
  });

  it("submits rejection with request id, reason, and note", async () => {
    const onReject = vi.fn().mockResolvedValue(undefined);
    renderPanel({ onReject });

    fireEvent.click(
      screen.getByLabelText("رفض طلب مراجعة merchant_review_entry-001"),
    );
    fireEvent.change(screen.getByLabelText("سبب الرفض (مطلوب)"), {
      target: { value: "الوصل لا يطابق العملية" },
    });
    fireEvent.change(screen.getByLabelText("ملاحظة داخلية للأدمن (اختياري)"), {
      target: { value: "راجعت الوصل يدويًا" },
    });
    fireEvent.click(
      screen.getByRole("button", { name: "تأكيد رفض طلب التاجر" }),
    );

    await waitFor(() => {
      expect(onReject).toHaveBeenCalledWith(
        "merchant_review_entry-001",
        "الوصل لا يطابق العملية",
        "راجعت الوصل يدويًا",
      );
    });
  });

  it("shows finance admin second approval path for amount 120", () => {
    renderPanel({ requests: [makeRequest({ originalAmount: 120 })] });

    fireEvent.click(
      screen.getByLabelText("اعتماد طلب مراجعة merchant_review_entry-001"),
    );

    expect(
      screen.getByText("سيتطلب موافقة ثانية من finance_admin"),
    ).toBeTruthy();
  });

  it("shows super admin second approval path for amount 600", () => {
    renderPanel({ requests: [makeRequest({ originalAmount: 600 })] });

    fireEvent.click(
      screen.getByLabelText("اعتماد طلب مراجعة merchant_review_entry-001"),
    );

    expect(
      screen.getByText("سيتطلب موافقة ثانية من super_admin"),
    ).toBeTruthy();
  });
});
