import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { StepUpModal } from "./step-up-modal";

describe("StepUpModal", () => {
  it("renders nothing when closed", () => {
    render(
      <StepUpModal
        open={false}
        pending={false}
        onSubmit={vi.fn()}
        onClose={vi.fn()}
      />,
    );

    expect(screen.queryByTestId("step-up-dialog")).toBeNull();
  });

  it("submits the entered password", async () => {
    const onSubmit = vi.fn().mockResolvedValue(undefined);

    render(
      <StepUpModal
        open
        command="approve_topup"
        pending={false}
        onSubmit={onSubmit}
        onClose={vi.fn()}
      />,
    );

    fireEvent.change(screen.getByLabelText("كلمة المرور"), {
      target: { value: "StrongPass123!" },
    });
    fireEvent.click(screen.getByRole("button", { name: "تأكيد ومتابعة" }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalledWith("StrongPass123!");
    });
    expect(screen.getByText("اعتماد طلب الشحن")).toBeTruthy();
  });

  it("closes via cancel action when not pending", () => {
    const onClose = vi.fn();

    render(
      <StepUpModal
        open
        pending={false}
        error="خطأ"
        onSubmit={vi.fn()}
        onClose={onClose}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "إلغاء" }));
    expect(onClose).toHaveBeenCalledTimes(1);
    expect(screen.getByTestId("step-up-error").textContent).toBe("خطأ");
  });

  it("focuses password input, closes with Escape, and restores trigger focus", async () => {
    const onClose = vi.fn();
    const renderHarness = (
      open: boolean,
      returnFocusTo?: HTMLElement | null,
    ) => (
      <>
        <button type="button">فتح التأكيد</button>
        <StepUpModal
          open={open}
          pending={false}
          returnFocusTo={returnFocusTo}
          onSubmit={vi.fn()}
          onClose={onClose}
        />
      </>
    );

    const { rerender } = render(renderHarness(false));

    const trigger = screen.getByRole("button", { name: "فتح التأكيد" });
    trigger.focus();
    const restoreFocusSpy = vi.spyOn(trigger, "focus");
    rerender(renderHarness(true, trigger));

    const input = screen.getByLabelText("كلمة المرور");
    await waitFor(() => {
      expect(document.activeElement).toBe(input);
    });

    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).toHaveBeenCalledTimes(1);
    rerender(renderHarness(false, trigger));

    await waitFor(() => {
      expect(screen.queryByTestId("step-up-dialog")).toBeNull();
      expect(restoreFocusSpy).toHaveBeenCalled();
    });
  });

  it("traps keyboard focus inside the modal", async () => {
    render(
      <StepUpModal
        open
        pending={false}
        onSubmit={vi.fn()}
        onClose={vi.fn()}
      />,
    );

    const closeButton = screen.getByRole("button", { name: "إغلاق" });
    const submitButton = screen.getByRole("button", { name: "تأكيد ومتابعة" });

    closeButton.focus();
    fireEvent.keyDown(document, { key: "Tab", shiftKey: true });
    expect(document.activeElement).toBe(submitButton);

    fireEvent.keyDown(document, { key: "Tab" });
    expect(document.activeElement).toBe(closeButton);
  });

  it("shows a visible lockout countdown and disables retry controls", async () => {
    const retryAt = new Date(Date.now() + 125_000).toISOString();

    render(
      <StepUpModal
        open
        pending={false}
        lockoutExpiresAt={retryAt}
        onSubmit={vi.fn()}
        onClose={vi.fn()}
      />,
    );

    await waitFor(() => {
      expect(screen.getByTestId("step-up-lockout-countdown").textContent).toMatch(
        /يمكن إعادة المحاولة بعد: 0[12]:/i,
      );
    });

    const input = screen.getByLabelText("كلمة المرور") as HTMLInputElement;
    const submitButton = screen.getByRole("button", {
      name: "تأكيد ومتابعة",
    }) as HTMLButtonElement;
    expect(input.disabled).toBe(true);
    expect(submitButton.disabled).toBe(true);
  });

  it("can toggle password visibility without submitting", () => {
    const onSubmit = vi.fn();

    render(
      <StepUpModal
        open
        pending={false}
        onSubmit={onSubmit}
        onClose={vi.fn()}
      />,
    );

    const input = screen.getByLabelText("كلمة المرور") as HTMLInputElement;
    expect(input.type).toBe("password");

    fireEvent.click(screen.getByRole("button", { name: "إظهار كلمة المرور" }));
    expect(input.type).toBe("text");
    expect(onSubmit).not.toHaveBeenCalled();
  });
});
