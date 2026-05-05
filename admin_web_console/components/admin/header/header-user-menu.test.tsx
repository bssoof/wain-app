import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { HeaderUserMenu } from "./header-user-menu";

describe("HeaderUserMenu", () => {
  it("shows user initials and name", () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    expect(screen.getByText("LA")).toBeTruthy();
    expect(screen.getByText("Local Admin")).toBeTruthy();
  });

  it("opens menu on click", () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: /Local Admin/i }));

    expect(screen.getByRole("menu")).toBeTruthy();
    expect(screen.getByRole("menuitem", { name: "الإعدادات" })).toBeTruthy();
  });

  it("aria-expanded toggles", () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    const trigger = screen.getByRole("button", { name: /Local Admin/i });
    expect(trigger.getAttribute("aria-expanded")).toBe("false");

    fireEvent.click(trigger);
    expect(trigger.getAttribute("aria-expanded")).toBe("true");

    fireEvent.click(trigger);
    expect(trigger.getAttribute("aria-expanded")).toBe("false");
  });

  it("Escape closes menu", () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: /Local Admin/i }));
    fireEvent.keyDown(document, { key: "Escape" });

    expect(screen.queryByRole("menu")).toBeNull();
  });

  it("clicking sign out calls onSignOut", () => {
    const onSignOut = vi.fn();
    render(<HeaderUserMenu userName="Local Admin" onSignOut={onSignOut} />);

    fireEvent.click(screen.getByRole("button", { name: /Local Admin/i }));
    fireEvent.click(screen.getByRole("menuitem", { name: "تسجيل الخروج" }));

    expect(onSignOut).toHaveBeenCalledTimes(1);
  });

  it("keyboard navigation Down moves between menu items", async () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    const trigger = screen.getByRole("button", { name: /Local Admin/i });
    fireEvent.keyDown(trigger, { key: "ArrowDown" });

    await waitFor(() => {
      expect(document.activeElement).toBe(
        screen.getByRole("menuitem", { name: "الإعدادات" }),
      );
    });

    fireEvent.keyDown(screen.getByRole("menuitem", { name: "الإعدادات" }), {
      key: "ArrowDown",
    });

    expect(document.activeElement).toBe(
      screen.getByRole("menuitem", { name: "تسجيل الخروج" }),
    );
  });

  it("keyboard navigation Up wraps to the last menu item", async () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    const trigger = screen.getByRole("button", { name: /Local Admin/i });
    fireEvent.keyDown(trigger, { key: "ArrowUp" });

    await waitFor(() => {
      expect(document.activeElement).toBe(
        screen.getByRole("menuitem", { name: "تسجيل الخروج" }),
      );
    });
  });

  it("click outside closes the menu", () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: /Local Admin/i }));
    fireEvent.mouseDown(document.body);

    expect(screen.queryByRole("menu")).toBeNull();
  });

  it("Tab traps focus inside the dropdown", () => {
    render(<HeaderUserMenu userName="Local Admin" onSignOut={vi.fn()} />);

    fireEvent.click(screen.getByRole("button", { name: /Local Admin/i }));
    fireEvent.keyDown(document, { key: "Tab" });
    expect(document.activeElement).toBe(
      screen.getByRole("menuitem", { name: "الإعدادات" }),
    );

    fireEvent.keyDown(document, { key: "Tab", shiftKey: true });
    expect(document.activeElement).toBe(
      screen.getByRole("menuitem", { name: "تسجيل الخروج" }),
    );
  });
});
