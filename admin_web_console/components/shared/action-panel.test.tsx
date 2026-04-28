import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";

import {
  ActionPanel,
  ActionPanelActions,
  ActionPanelHeader,
  ActionPanelItem,
  ActionPanelMessage,
} from "./action-panel";

describe("ActionPanel", () => {
  it("renders normalized action stack primitives with stable hooks", () => {
    render(
      <ActionPanel testId="panel-stack">
        <ActionPanelItem testId="panel-item">
          <ActionPanelHeader testId="panel-header">
            <button type="button">تشغيل</button>
          </ActionPanelHeader>
          <ActionPanelActions testId="panel-actions">
            <button type="button">أول</button>
          </ActionPanelActions>
          <ActionPanelMessage testId="panel-message">تمت المعالجة</ActionPanelMessage>
        </ActionPanelItem>
      </ActionPanel>,
    );

    expect(screen.getByTestId("panel-stack").className).toContain("action-panel");
    expect(screen.getByTestId("panel-item").className).toContain("action-panel__item");
    expect(screen.getByTestId("panel-header").className).toContain("action-panel__header");
    expect(screen.getByTestId("panel-actions").className).toContain("action-panel__actions");
    expect(screen.getByTestId("panel-message").className).toContain("action-panel__message");
    expect(screen.getByTestId("panel-message").tagName).toBe("P");
  });

  it("keeps legacy class hooks and passthrough attributes", () => {
    render(
      <ActionPanel className="media-action-stack" testId="legacy-stack">
        <ActionPanelItem
          className="media-action-item"
          testId="legacy-item"
          title="legacy-row"
        >
          <ActionPanelHeader className="media-action-item__header" testId="legacy-header">
            رأس
          </ActionPanelHeader>
          <ActionPanelMessage className="media-action-message muted-text" testId="legacy-message">
            رسالة
          </ActionPanelMessage>
        </ActionPanelItem>
      </ActionPanel>,
    );

    const stack = screen.getByTestId("legacy-stack");
    const item = screen.getByTestId("legacy-item");
    const header = screen.getByTestId("legacy-header");
    const message = screen.getByTestId("legacy-message");

    expect(stack.className).toContain("action-panel");
    expect(stack.className).toContain("media-action-stack");
    expect(item.className).toContain("action-panel__item");
    expect(item.className).toContain("media-action-item");
    expect(item.getAttribute("title")).toBe("legacy-row");
    expect(header.className).toContain("action-panel__header");
    expect(header.className).toContain("media-action-item__header");
    expect(message.className).toContain("action-panel__message");
    expect(message.className).toContain("media-action-message");
  });
});