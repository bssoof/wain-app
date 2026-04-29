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
});
