import { fireEvent, render, screen } from "@testing-library/react";
import { Search, Settings, Trash2 } from "lucide-react";
import { describe, expect, it, vi } from "vitest";

import { IconButton } from "./icon-button";

describe("IconButton", () => {
  it("applies the label prop as aria-label", () => {
    render(<IconButton icon={Search} label="بحث" />);

    const button = screen.getByRole("button", { name: "بحث" });
    expect(button.getAttribute("aria-label")).toBe("بحث");
  });

  it("calls onClick when clicked and not when loading", () => {
    const onReadyClick = vi.fn();
    const onLoadingClick = vi.fn();

    render(
      <>
        <IconButton icon={Search} label="تشغيل" onClick={onReadyClick} />
        <IconButton icon={Search} label="تحميل" loading onClick={onLoadingClick} />
      </>,
    );

    fireEvent.click(screen.getByRole("button", { name: "تشغيل" }));
    fireEvent.click(screen.getByRole("button", { name: "تحميل" }));

    expect(onReadyClick).toHaveBeenCalledTimes(1);
    expect(onLoadingClick).toHaveBeenCalledTimes(0);
  });

  it("shows a spinner instead of the icon when loading", () => {
    render(<IconButton icon={Search} label="تحميل" loading />);

    const button = screen.getByRole("button", { name: "تحميل" });
    expect(button.querySelector(".icon-button__spinner")).not.toBeNull();
    expect(button.querySelector(".icon-button__icon")).toBeNull();
    expect(button.getAttribute("aria-busy")).toBe("true");
  });

  it("applies all variant classes", () => {
    render(
      <>
        <IconButton icon={Search} label="ghost" variant="ghost" />
        <IconButton icon={Settings} label="primary" variant="primary" />
        <IconButton icon={Trash2} label="danger" variant="danger" />
      </>,
    );

    expect(screen.getByRole("button", { name: "ghost" }).className).toContain(
      "icon-button--ghost",
    );
    expect(screen.getByRole("button", { name: "primary" }).className).toContain(
      "icon-button--primary",
    );
    expect(screen.getByRole("button", { name: "danger" }).className).toContain(
      "icon-button--danger",
    );
  });

  it("applies size classes and disables the button while loading", () => {
    render(
      <>
        <IconButton icon={Search} label="صغير" size="sm" />
        <IconButton icon={Search} label="متوسط" loading size="md" />
      </>,
    );

    expect(screen.getByRole("button", { name: "صغير" }).className).toContain(
      "icon-button--sm",
    );
    const mediumButton = screen.getByRole("button", { name: "متوسط" });
    expect(mediumButton.className).toContain("icon-button--md");
    expect((mediumButton as HTMLButtonElement).disabled).toBe(true);
  });
});
