import { act, fireEvent, render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { Tooltip } from "./tooltip";

describe("Tooltip", () => {
  afterEach(() => {
    vi.useRealTimers();
  });

  it("renders children", () => {
    render(
      <Tooltip content="شرح">
        <button type="button">زر</button>
      </Tooltip>,
    );

    expect(screen.getByRole("button", { name: "زر" })).not.toBeNull();
  });

  it("shows the tooltip after the hover delay", () => {
    vi.useFakeTimers();
    render(
      <Tooltip content="شرح متأخر" delayMs={300}>
        <button type="button">زر</button>
      </Tooltip>,
    );

    const button = screen.getByRole("button", { name: "زر" });
    const wrapper = button.parentElement;
    const tooltip = screen.getByRole("tooltip");

    expect(tooltip.getAttribute("data-visible")).toBe("false");
    fireEvent.mouseEnter(wrapper!);

    act(() => {
      vi.advanceTimersByTime(299);
    });
    expect(tooltip.getAttribute("data-visible")).toBe("false");

    act(() => {
      vi.advanceTimersByTime(1);
    });
    expect(tooltip.getAttribute("data-visible")).toBe("true");
  });

  it("shows the tooltip immediately on focus", () => {
    render(
      <Tooltip content="شرح فوري">
        <button type="button">زر</button>
      </Tooltip>,
    );

    const button = screen.getByRole("button", { name: "زر" });
    fireEvent.focus(button);

    expect(screen.getByRole("tooltip").getAttribute("data-visible")).toBe("true");
  });

  it("hides on blur and mouseleave", () => {
    vi.useFakeTimers();
    render(
      <Tooltip content="شرح" delayMs={10}>
        <button type="button">زر</button>
      </Tooltip>,
    );

    const button = screen.getByRole("button", { name: "زر" });
    const wrapper = button.parentElement;
    const tooltip = screen.getByRole("tooltip");

    fireEvent.focus(button);
    expect(tooltip.getAttribute("data-visible")).toBe("true");
    fireEvent.blur(button);
    expect(tooltip.getAttribute("data-visible")).toBe("false");

    fireEvent.mouseEnter(wrapper!);
    act(() => {
      vi.advanceTimersByTime(10);
    });
    expect(tooltip.getAttribute("data-visible")).toBe("true");
    fireEvent.mouseLeave(wrapper!);
    expect(tooltip.getAttribute("data-visible")).toBe("false");
  });

  it("sets aria-describedby on the child element", () => {
    render(
      <Tooltip content="شرح">
        <button type="button">زر</button>
      </Tooltip>,
    );

    const button = screen.getByRole("button", { name: "زر" });
    const tooltip = screen.getByRole("tooltip");

    expect(button.getAttribute("aria-describedby")).toBe(tooltip.getAttribute("id"));
  });
});
