import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { ConfirmDialog } from "./confirm-dialog";

describe("ConfirmDialog", () => {
  it("returns null when open is false", () => {
    render(
      <ConfirmDialog
        open={false}
        title="حذف الطلب"
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    expect(screen.queryByRole("dialog")).toBeNull();
  });

  it("renders title and description when open", () => {
    render(
      <ConfirmDialog
        open
        title="تأكيد الإجراء"
        description="لا يمكن التراجع بعد التنفيذ."
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    expect(screen.getByRole("heading", { name: "تأكيد الإجراء" })).toBeTruthy();
    expect(screen.getByText("لا يمكن التراجع بعد التنفيذ.")).toBeTruthy();
  });

  it("calls onClose on Escape when not loading", () => {
    const onClose = vi.fn();

    render(
      <ConfirmDialog
        open
        title="تأكيد الإجراء"
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    );

    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("calls onClose on backdrop click when not loading", () => {
    const onClose = vi.fn();

    render(
      <ConfirmDialog
        open
        title="تأكيد الإجراء"
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    );

    fireEvent.click(screen.getByTestId("confirm-dialog-backdrop"));
    expect(onClose).toHaveBeenCalledTimes(1);
  });

  it("calls onConfirm on confirm click", () => {
    const onConfirm = vi.fn();

    render(
      <ConfirmDialog
        open
        title="تأكيد الإجراء"
        onClose={vi.fn()}
        onConfirm={onConfirm}
      />,
    );

    fireEvent.click(screen.getByRole("button", { name: "تأكيد" }));
    expect(onConfirm).toHaveBeenCalledTimes(1);
  });

  it("does not call onClose on Escape when loading is true", () => {
    const onClose = vi.fn();

    render(
      <ConfirmDialog
        open
        loading
        title="تأكيد الإجراء"
        onClose={onClose}
        onConfirm={vi.fn()}
      />,
    );

    fireEvent.keyDown(document, { key: "Escape" });
    expect(onClose).not.toHaveBeenCalled();
  });

  it("adds danger class to confirm button when variant is danger", () => {
    render(
      <ConfirmDialog
        open
        title="حذف دائم"
        variant="danger"
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    expect(screen.getByRole("button", { name: "تأكيد" }).className).toContain(
      "confirm-dialog__btn--danger",
    );
  });

  it("has role dialog and aria-modal true", () => {
    render(
      <ConfirmDialog
        open
        title="تأكيد الإجراء"
        description="راجع البيانات قبل التنفيذ."
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    const dialog = screen.getByRole("dialog");
    expect(dialog.getAttribute("aria-modal")).toBe("true");
    expect(dialog.getAttribute("aria-labelledby")).toBeTruthy();
    expect(dialog.getAttribute("aria-describedby")).toBeTruthy();
  });

  it("disables confirm button when loading is true", () => {
    render(
      <ConfirmDialog
        open
        loading
        title="تأكيد الإجراء"
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    expect(
      (screen.getByRole("button", { name: "جارٍ التنفيذ..." }) as HTMLButtonElement)
        .disabled,
    ).toBe(true);
  });

  it("focuses confirm on open and restores focus after close", async () => {
    const trigger = document.createElement("button");
    trigger.textContent = "فتح";
    document.body.appendChild(trigger);
    trigger.focus();
    const restoreFocusSpy = vi.spyOn(trigger, "focus");

    const { rerender } = render(
      <ConfirmDialog
        open
        title="تأكيد الإجراء"
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    await waitFor(() => {
      expect(document.activeElement).toBe(screen.getByRole("button", { name: "تأكيد" }));
    });

    rerender(
      <ConfirmDialog
        open={false}
        title="تأكيد الإجراء"
        onClose={vi.fn()}
        onConfirm={vi.fn()}
      />,
    );

    await waitFor(() => {
      expect(restoreFocusSpy).toHaveBeenCalled();
    });

    restoreFocusSpy.mockRestore();
    trigger.remove();
  });
});
