import { render, screen, waitFor } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { useMerchantReversalRequests } from "./use-merchant-reversal-requests";

const { onSnapshotMock, unsubscribeMock } = vi.hoisted(() => ({
  onSnapshotMock: vi.fn(),
  unsubscribeMock: vi.fn(),
}));

vi.mock("@/lib/firebase/client", () => ({
  firestoreDb: { app: "test-firestore" },
}));

vi.mock("firebase/firestore", () => ({
  collection: vi.fn((_db, path: string) => ({ path })),
  onSnapshot: (...args: unknown[]) => onSnapshotMock(...args),
  orderBy: vi.fn((field: string, direction: string) => ({
    field,
    direction,
    type: "orderBy",
  })),
  query: vi.fn((...parts: unknown[]) => ({ parts })),
  where: vi.fn((field: string, op: string, value: unknown) => ({
    field,
    op,
    value,
    type: "where",
  })),
}));

function timestamp(iso: string) {
  const date = new Date(iso);
  return {
    toDate: () => date,
    toMillis: () => date.getTime(),
  };
}

function requestDoc(id = "merchant_review_entry_001") {
  return {
    id,
    data: () => ({
      request_id: id,
      source: "merchant",
      status: "pending_review",
      venue_id: "venue_001",
      entry_id: "entry_001",
      original_amount: 50,
      currency: "ILS",
      original_feature_key: "story_promotion",
      requested_by_uid: "merchant_001",
      reason: "الخدمة لم تكتمل بعد الخصم",
      merchant_note: null,
      created_at: timestamp("2026-05-12T08:00:00.000Z"),
      updated_at: timestamp("2026-05-12T08:00:00.000Z"),
    }),
  };
}

function RequestsProbe() {
  const { requests, isLoading, error, refresh } = useMerchantReversalRequests();
  return (
    <div>
      <span data-testid="loading">{String(isLoading)}</span>
      <span data-testid="error">{error ?? ""}</span>
      <span data-testid="count">{requests.length}</span>
      <span data-testid="first">{requests[0]?.requestId ?? ""}</span>
      <button onClick={refresh} type="button">
        refresh
      </button>
    </div>
  );
}

describe("useMerchantReversalRequests", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    onSnapshotMock.mockReturnValue(unsubscribeMock);
  });

  it("returns loading first, then maps pending merchant requests", async () => {
    onSnapshotMock.mockImplementation((_query, onNext) => {
      setTimeout(() => onNext({ docs: [requestDoc()] }), 0);
      return unsubscribeMock;
    });

    render(<RequestsProbe />);

    expect(screen.getByTestId("loading").textContent).toBe("true");

    await waitFor(() => {
      expect(screen.getByTestId("count").textContent).toBe("1");
    });
    expect(screen.getByTestId("loading").textContent).toBe("false");
    expect(screen.getByTestId("first").textContent).toBe(
      "merchant_review_entry_001",
    );
  });

  it("returns an error when the live subscription fails", async () => {
    onSnapshotMock.mockImplementation((_query, _onNext, onError) => {
      setTimeout(() => onError(new Error("permission denied")), 0);
      return unsubscribeMock;
    });

    render(<RequestsProbe />);

    await waitFor(() => {
      expect(screen.getByTestId("error").textContent).toBe("permission denied");
    });
    expect(screen.getByTestId("loading").textContent).toBe("false");
  });
});
