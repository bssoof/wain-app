import { useEffect } from "react";
import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { ToastViewport, useToast } from "./toast";

type ToastApi = ReturnType<typeof useToast>;
type ToastInput = Parameters<ToastApi["show"]>[0];

let cleanupApi: ToastApi | null = null;
let createdToastIds: string[] = [];

afterEach(() => {
  if (cleanupApi) {
    act(() => {
      createdToastIds.forEach((id) => cleanupApi?.dismiss(id));
    });
  }

  cleanupApi = null;
  createdToastIds = [];
  vi.useRealTimers();
});

describe("ToastViewport and useToast", () => {
  it("useToast.show returns a string id", () => {
    const { show } = setupToastViewport();

    const id = show({ title: "تم الحفظ", durationMs: 0 });

    expect(typeof id).toBe("string");
    expect(id.length).toBeGreaterThan(0);
  });

  it("ToastViewport renders shown toasts", () => {
    const { rerender, show, tree } = setupToastViewport();

    show({
      title: "تمت المزامنة",
      description: "تم تحديث بيانات لوحة التحكم.",
      durationMs: 0,
    });
    rerender(tree);

    expect(screen.getByText("تمت المزامنة")).toBeTruthy();
    expect(screen.getByText("تم تحديث بيانات لوحة التحكم.")).toBeTruthy();
  });

  it("uses role alert for danger severity", () => {
    const { show } = setupToastViewport();

    show({ title: "فشل التنفيذ", severity: "danger", durationMs: 0 });

    expect(screen.getByRole("alert").textContent).toContain("فشل التنفيذ");
  });

  it("uses role status for info severity", () => {
    const { show } = setupToastViewport();

    show({ title: "معلومة جديدة", severity: "info", durationMs: 0 });

    expect(screen.getByRole("status").textContent).toContain("معلومة جديدة");
  });

  it("auto-dismisses after durationMs", () => {
    vi.useFakeTimers();
    const { show } = setupToastViewport();

    show({ title: "سيختفي", durationMs: 50 });
    expect(screen.getByText("سيختفي")).toBeTruthy();

    act(() => {
      vi.advanceTimersByTime(49);
    });
    expect(screen.getByText("سيختفي")).toBeTruthy();

    act(() => {
      vi.advanceTimersByTime(1);
    });
    expect(screen.queryByText("سيختفي")).toBeNull();
  });

  it("dismiss removes toast immediately", () => {
    const { dismiss, show } = setupToastViewport();

    const id = show({ title: "إزالة فورية", durationMs: 0 });
    dismiss(id);

    expect(screen.queryByText("إزالة فورية")).toBeNull();
  });

  it("renders a maximum of 3 visible toasts and drops the oldest", () => {
    const { show } = setupToastViewport();

    show({ title: "الأول", durationMs: 0 });
    show({ title: "الثاني", durationMs: 0 });
    show({ title: "الثالث", durationMs: 0 });
    show({ title: "الرابع", durationMs: 0 });

    expect(screen.queryByText("الأول")).toBeNull();
    expect(screen.getByText("الثاني")).toBeTruthy();
    expect(screen.getByText("الثالث")).toBeTruthy();
    expect(screen.getByText("الرابع")).toBeTruthy();
    expect(screen.getAllByRole("status")).toHaveLength(3);
  });

  it("pauses auto-dismiss on hover and resumes on mouseleave", () => {
    vi.useFakeTimers();
    const { show } = setupToastViewport();

    show({ title: "مؤقت قابل للإيقاف", durationMs: 100 });
    const toast = screen.getByRole("status");

    act(() => {
      vi.advanceTimersByTime(40);
    });
    fireEvent.mouseEnter(toast);
    act(() => {
      vi.advanceTimersByTime(200);
    });
    expect(screen.getByText("مؤقت قابل للإيقاف")).toBeTruthy();

    fireEvent.mouseLeave(toast);
    act(() => {
      vi.advanceTimersByTime(59);
    });
    expect(screen.getByText("مؤقت قابل للإيقاف")).toBeTruthy();

    act(() => {
      vi.advanceTimersByTime(1);
    });
    expect(screen.queryByText("مؤقت قابل للإيقاف")).toBeNull();
  });
});

function ToastHarness({ onReady }: { onReady: (api: ToastApi) => void }) {
  const api = useToast();

  useEffect(() => {
    onReady(api);
  }, [api, onReady]);

  return null;
}

function setupToastViewport() {
  let api: ToastApi | null = null;
  const handleReady = (nextApi: ToastApi) => {
    api = nextApi;
    cleanupApi = nextApi;
  };
  const tree = (
    <>
      <ToastHarness onReady={handleReady} />
      <ToastViewport />
    </>
  );
  const renderResult = render(tree);

  if (!api) {
    throw new Error("Toast test harness did not initialize");
  }

  const show = (toast: ToastInput) => {
    let id = "";
    act(() => {
      id = api?.show(toast) ?? "";
    });
    createdToastIds.push(id);
    return id;
  };

  const dismiss = (id: string) => {
    act(() => {
      api?.dismiss(id);
    });
  };

  return {
    ...renderResult,
    dismiss,
    show,
    tree,
  };
}
