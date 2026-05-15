import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AdminSession } from "@/lib/auth/guard-api";
import type { MerchantReversalRequest } from "@/lib/finance/read-models";

import { MerchantReversalReviewContainer } from "./merchant-reversal-review-container";

const {
  executeReviewMock,
  refreshMock,
  sessionState,
  toastShowMock,
  useRequestsMock,
} = vi.hoisted(() => ({
  executeReviewMock: vi.fn(),
  refreshMock: vi.fn(),
  sessionState: {
    value: {
      uid: "finance_admin_001",
      primaryRole: "finance_admin",
      roles: ["finance_admin"],
      roleSource: "claims",
    },
  },
  toastShowMock: vi.fn(),
  useRequestsMock: vi.fn(),
}));

vi.mock("@/components/finance/finance-command-provider", () => ({
  useFinanceCommands: () => ({
    session: sessionState.value,
  }),
}));

vi.mock("@/components/shared/ui/toast", () => ({
  useToast: () => ({
    show: toastShowMock,
    dismiss: vi.fn(),
  }),
}));

vi.mock("@/lib/finance/use-merchant-reversal-requests", () => ({
  useMerchantReversalRequests: () => useRequestsMock(),
}));

vi.mock("@/lib/finance/use-review-merchant-reversal", async (importActual) => {
  const actual =
    await importActual<typeof import("@/lib/finance/use-review-merchant-reversal")>();
  return {
    ...actual,
    useReviewMerchantReversal: () => ({
      execute: executeReviewMock,
    }),
  };
});

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
    requestId: "merchant_review_entry_001",
    source: "merchant",
    status: "pending_review",
    venueId: "venue_001",
    entryId: "entry_001",
    originalAmount: 50,
    currency: "ILS",
    originalFeatureKey: "story_promotion",
    requestedByUid: "merchant_uid_001",
    reason: "تم خصم الرصيد ولم تكتمل الخدمة بنجاح.",
    merchantNote: null,
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

function mockRequests(requests = [makeRequest()]) {
  useRequestsMock.mockReturnValue({
    requests,
    isLoading: false,
    error: null,
    refresh: refreshMock,
  });
}

describe("MerchantReversalReviewContainer", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    sessionState.value = {
      uid: "finance_admin_001",
      primaryRole: "finance_admin",
      roles: ["finance_admin"],
      roleSource: "claims",
    } satisfies AdminSession;
    mockRequests();
  });

  it("shows a direct execution toast and refreshes after approve success", async () => {
    executeReviewMock.mockResolvedValue({
      action: "review_merchant_reversal",
      requestId: "merchant_review_entry_001",
      status: "approved_and_executed",
      reversalEntryId: "reversal_entry_001",
    });

    render(<MerchantReversalReviewContainer />);
    fireEvent.click(
      screen.getByRole("button", {
        name: "اعتماد طلب مراجعة merchant_review_entry_001",
      }),
    );
    fireEvent.click(screen.getByRole("button", { name: "تأكيد اعتماد طلب التاجر" }));

    await waitFor(() => {
      expect(toastShowMock).toHaveBeenCalledWith({
        severity: "success",
        title: "تم تنفيذ التصحيح",
      });
    });
    expect(refreshMock).toHaveBeenCalledTimes(1);
  });

  it("shows a second approval toast when approve requires another admin", async () => {
    mockRequests([makeRequest({ originalAmount: 150 })]);
    executeReviewMock.mockResolvedValue({
      action: "review_merchant_reversal",
      requestId: "merchant_review_entry_001",
      status: "pending_second_approval",
      requiredSecondApproverRole: "finance_admin",
    });

    render(<MerchantReversalReviewContainer />);
    fireEvent.click(
      screen.getByRole("button", {
        name: "اعتماد طلب مراجعة merchant_review_entry_001",
      }),
    );
    fireEvent.click(screen.getByRole("button", { name: "تأكيد اعتماد طلب التاجر" }));

    await waitFor(() => {
      expect(toastShowMock).toHaveBeenCalledWith({
        severity: "info",
        title: "تم اعتماد الطلب — بانتظار موافقة ثانية من finance_admin",
      });
    });
  });

  it("shows a reject toast and refreshes after reject success", async () => {
    executeReviewMock.mockResolvedValue({
      action: "review_merchant_reversal",
      requestId: "merchant_review_entry_001",
      status: "rejected",
    });

    render(<MerchantReversalReviewContainer />);
    fireEvent.click(
      screen.getByRole("button", {
        name: "رفض طلب مراجعة merchant_review_entry_001",
      }),
    );
    fireEvent.change(screen.getByLabelText("سبب الرفض (مطلوب)"), {
      target: { value: "تم التحقق ولا يوجد خطأ مالي." },
    });
    fireEvent.click(screen.getByRole("button", { name: "تأكيد رفض طلب التاجر" }));

    await waitFor(() => {
      expect(toastShowMock).toHaveBeenCalledWith({
        severity: "success",
        title: "تم رفض الطلب",
      });
    });
    expect(refreshMock).toHaveBeenCalledTimes(1);
  });

  it("keeps the modal open and shows an error when the callable fails", async () => {
    executeReviewMock.mockRejectedValue(new Error("entry_already_reversed"));

    render(<MerchantReversalReviewContainer />);
    fireEvent.click(
      screen.getByRole("button", {
        name: "اعتماد طلب مراجعة merchant_review_entry_001",
      }),
    );
    fireEvent.click(screen.getByRole("button", { name: "تأكيد اعتماد طلب التاجر" }));

    await waitFor(() => {
      expect(screen.getByRole("dialog")).toBeTruthy();
      expect(
        screen.getByText("تم تصحيح هذه العملية من قِبل أدمن آخر"),
      ).toBeTruthy();
    });
    expect(toastShowMock).toHaveBeenCalledWith({
      severity: "danger",
      title: "تم تصحيح هذه العملية من قِبل أدمن آخر",
    });
  });

  it("renders readonly mode when the session cannot create reversals", () => {
    sessionState.value = {
      uid: "support_admin_001",
      primaryRole: "support_admin",
      roles: ["support_admin"],
      roleSource: "claims",
    } satisfies AdminSession;

    render(<MerchantReversalReviewContainer />);

    expect(
      screen.getByTestId("merchant-reversal-readonly-banner"),
    ).toBeTruthy();
    expect(screen.queryByRole("button", { name: /اعتماد طلب مراجعة/ })).toBeNull();
  });
});
