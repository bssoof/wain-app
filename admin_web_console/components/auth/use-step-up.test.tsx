import { act, renderHook, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { useStepUp } from "@/lib/auth/use-step-up";

describe("useStepUp", () => {
  it("skips status checks for non-sensitive commands", async () => {
    const fetchMock = vi.fn<typeof fetch>();

    const { result } = renderHook(() =>
      useStepUp({
        scope: "finance",
        fetchImpl: fetchMock,
        bypassInTests: false,
      }),
    );

    const ensured = await result.current.ensureStepUp("verify_wallet_readiness");
    expect(ensured).toEqual({ ok: true });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("opens challenge and resolves after successful re-auth + issue", async () => {
    const fetchMock = vi.fn<typeof fetch>(async (input) => {
      const url = String(input);
      if (url.includes("/api/admin/step-up/status")) {
        return new Response(JSON.stringify({ success: true, required: true }), {
          status: 200,
        });
      }

      if (url.includes("/api/admin/step-up/issue")) {
        return new Response(JSON.stringify({ success: true }), { status: 200 });
      }

      throw new Error(`Unexpected URL: ${url}`);
    });
    const reauthMock = vi.fn(async () => "fresh-id-token");

    const { result } = renderHook(() =>
      useStepUp({
        scope: "finance",
        fetchImpl: fetchMock,
        bypassInTests: false,
        reauthenticateAndGetFreshIdToken: reauthMock,
      }),
    );

    let ensurePromise: Promise<Awaited<ReturnType<typeof result.current.ensureStepUp>>>;
    await act(async () => {
      ensurePromise = result.current.ensureStepUp("approve_topup");
    });

    expect(result.current.modal.open).toBe(true);
    expect(result.current.modal.command).toBe("approve_topup");

    await act(async () => {
      await result.current.modal.onSubmit("StrongPass123!");
    });

    await expect(ensurePromise!).resolves.toEqual({ ok: true });
    expect(reauthMock).toHaveBeenCalledWith("StrongPass123!");
  });

  it("shows lockout error when issue endpoint returns 429", async () => {
    const fetchMock = vi.fn<typeof fetch>(async (input) => {
      const url = String(input);
      if (url.includes("/api/admin/step-up/status")) {
        return new Response(JSON.stringify({ success: true, required: true }), {
          status: 200,
        });
      }

      if (url.includes("/api/admin/step-up/issue")) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "Too many step-up attempts. Try again later.",
          }),
          { status: 429 },
        );
      }

      throw new Error(`Unexpected URL: ${url}`);
    });

    const { result } = renderHook(() =>
      useStepUp({
        scope: "finance",
        fetchImpl: fetchMock,
        bypassInTests: false,
        reauthenticateAndGetFreshIdToken: async () => "fresh-id-token",
      }),
    );

    let ensurePromise: Promise<Awaited<ReturnType<typeof result.current.ensureStepUp>>>;
    await act(async () => {
      ensurePromise = result.current.ensureStepUp("approve_topup");
    });

    await act(async () => {
      await result.current.modal.onSubmit("StrongPass123!");
    });

    await waitFor(() => {
      expect(result.current.modal.error).toContain("تم إيقاف محاولات التأكيد مؤقتًا");
    });

    await act(async () => {
      result.current.modal.onClose();
    });

    await expect(ensurePromise!).resolves.toEqual({
      ok: false,
      code: "step_up_required",
      message: "STEP_UP_REQUIRED",
      reason: "cancelled",
    });
  });

  it("preserves retryAt from 429 responses for visible lockout countdowns", async () => {
    const retryAt = new Date("2026-04-30T10:05:00.000Z").toISOString();
    const fetchMock = vi.fn<typeof fetch>(async (input) => {
      const url = String(input);
      if (url.includes("/api/admin/step-up/status")) {
        return new Response(JSON.stringify({ success: true, required: true }), {
          status: 200,
        });
      }

      if (url.includes("/api/admin/step-up/issue")) {
        return new Response(
          JSON.stringify({
            success: false,
            error: "Too many step-up attempts. Try again later.",
            retryAt,
          }),
          { status: 429 },
        );
      }

      throw new Error(`Unexpected URL: ${url}`);
    });

    const { result } = renderHook(() =>
      useStepUp({
        scope: "finance",
        fetchImpl: fetchMock,
        bypassInTests: false,
        reauthenticateAndGetFreshIdToken: async () => "fresh-id-token",
      }),
    );

    let ensurePromise: Promise<Awaited<ReturnType<typeof result.current.ensureStepUp>>>;
    await act(async () => {
      ensurePromise = result.current.ensureStepUp("approve_topup");
    });

    await act(async () => {
      await result.current.modal.onSubmit("StrongPass123!");
    });

    await waitFor(() => {
      expect(result.current.modal.lockoutExpiresAt).toBe(retryAt);
      expect(result.current.modal.error).toContain("العدّاد");
    });

    await act(async () => {
      result.current.modal.onClose();
    });

    await expect(ensurePromise!).resolves.toEqual({
      ok: false,
      code: "step_up_required",
      message: "STEP_UP_REQUIRED",
      reason: "cancelled",
    });
  });

  it("forces a new challenge without checking status when backend rejects an expired token", async () => {
    const fetchMock = vi.fn<typeof fetch>();

    const { result } = renderHook(() =>
      useStepUp({
        scope: "finance",
        fetchImpl: fetchMock,
      }),
    );

    let ensurePromise: Promise<Awaited<ReturnType<typeof result.current.ensureStepUp>>>;
    await act(async () => {
      ensurePromise = result.current.ensureStepUp("approve_topup", { force: true });
    });

    expect(result.current.modal.open).toBe(true);
    expect(result.current.modal.command).toBe("approve_topup");
    expect(fetchMock).not.toHaveBeenCalled();

    await act(async () => {
      result.current.modal.onClose();
    });

    await expect(ensurePromise!).resolves.toEqual({
      ok: false,
      code: "step_up_required",
      message: "STEP_UP_REQUIRED",
      reason: "cancelled",
    });
  });
});
