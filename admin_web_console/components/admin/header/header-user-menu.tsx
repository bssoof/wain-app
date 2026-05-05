"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import { ChevronDown } from "lucide-react";
import type { KeyboardEvent, MouseEvent as ReactMouseEvent } from "react";

export type HeaderUserMenuProps = {
  userName: string;
  userEmail?: string;
  onSignOut: () => void;
};

const MENU_ITEM_COUNT = 2;

export function HeaderUserMenu({
  userName,
  userEmail,
  onSignOut,
}: HeaderUserMenuProps): JSX.Element {
  const [open, setOpen] = useState(false);
  const [activeIndex, setActiveIndex] = useState(0);
  const rootRef = useRef<HTMLDivElement | null>(null);
  const triggerRef = useRef<HTMLButtonElement | null>(null);
  const itemRefs = useRef<Array<HTMLButtonElement | null>>([]);
  const initials = getInitials(userName);

  const focusItem = useCallback((index: number) => {
    setActiveIndex(index);
    itemRefs.current[index]?.focus();
  }, []);

  const openAndFocusItem = useCallback(
    (index: number) => {
      setOpen(true);
      setActiveIndex(index);
      window.setTimeout(() => {
        focusItem(index);
      }, 0);
    },
    [focusItem],
  );

  useEffect(() => {
    if (!open) {
      return;
    }

    const handleMouseDown = (event: MouseEvent) => {
      const rootElement = rootRef.current;
      if (rootElement && !rootElement.contains(event.target as Node)) {
        setOpen(false);
      }
    };

    const handleKeyDown = (event: globalThis.KeyboardEvent) => {
      if (event.key === "Escape") {
        event.preventDefault();
        setOpen(false);
        triggerRef.current?.focus();
        return;
      }

      if (event.key !== "Tab") {
        return;
      }

      event.preventDefault();
      const focusedIndex = itemRefs.current.findIndex(
        (item) => item === document.activeElement,
      );
      if (focusedIndex === -1) {
        focusItem(event.shiftKey ? MENU_ITEM_COUNT - 1 : 0);
        return;
      }

      const direction = event.shiftKey ? -1 : 1;
      const nextIndex = (focusedIndex + direction + MENU_ITEM_COUNT) % MENU_ITEM_COUNT;
      focusItem(nextIndex);
    };

    document.addEventListener("mousedown", handleMouseDown);
    document.addEventListener("keydown", handleKeyDown);
    return () => {
      document.removeEventListener("mousedown", handleMouseDown);
      document.removeEventListener("keydown", handleKeyDown);
    };
  }, [focusItem, open]);

  const closeMenu = () => {
    setOpen(false);
  };

  const handleTriggerClick = () => {
    setOpen((current) => !current);
  };

  const handleTriggerKeyDown = (event: KeyboardEvent<HTMLButtonElement>) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      openAndFocusItem(0);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      openAndFocusItem(MENU_ITEM_COUNT - 1);
    }
  };

  const handleMenuKeyDown = (
    event: KeyboardEvent<HTMLButtonElement>,
    index: number,
  ) => {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      focusItem((index + 1) % MENU_ITEM_COUNT);
    } else if (event.key === "ArrowUp") {
      event.preventDefault();
      focusItem((index - 1 + MENU_ITEM_COUNT) % MENU_ITEM_COUNT);
    } else if (event.key === "Home") {
      event.preventDefault();
      focusItem(0);
    } else if (event.key === "End") {
      event.preventDefault();
      focusItem(MENU_ITEM_COUNT - 1);
    }
  };

  const handleSignOutClick = (event: ReactMouseEvent<HTMLButtonElement>) => {
    event.preventDefault();
    onSignOut();
    closeMenu();
  };

  return (
    <div className="header-user-menu" ref={rootRef}>
      <button
        ref={triggerRef}
        type="button"
        className="header-user-menu__trigger"
        aria-haspopup="menu"
        aria-expanded={open}
        onClick={handleTriggerClick}
        onKeyDown={handleTriggerKeyDown}
      >
        <span className="header-user-menu__avatar" aria-hidden="true">
          {initials}
        </span>
        <span className="header-user-menu__name">{userName}</span>
        <ChevronDown aria-hidden="true" size={16} strokeWidth={2} />
      </button>

      {open ? (
        <div className="header-user-menu__dropdown" role="menu">
          {userEmail ? (
            <div className="header-user-menu__email" aria-label="بريد المستخدم">
              {userEmail}
            </div>
          ) : null}
          <button
            ref={(node) => {
              itemRefs.current[0] = node;
            }}
            type="button"
            className="header-user-menu__item"
            role="menuitem"
            tabIndex={activeIndex === 0 ? 0 : -1}
            onKeyDown={(event) => handleMenuKeyDown(event, 0)}
            onClick={closeMenu}
          >
            الإعدادات
          </button>
          <div className="header-user-menu__separator" role="separator" />
          <button
            ref={(node) => {
              itemRefs.current[1] = node;
            }}
            type="button"
            className="header-user-menu__item"
            role="menuitem"
            tabIndex={activeIndex === 1 ? 0 : -1}
            onKeyDown={(event) => handleMenuKeyDown(event, 1)}
            onClick={handleSignOutClick}
          >
            تسجيل الخروج
          </button>
        </div>
      ) : null}
    </div>
  );
}

function getInitials(userName: string): string {
  const words = userName.trim().split(/\s+/).filter(Boolean);
  if (words.length === 0) {
    return "؟";
  }

  if (words.length === 1) {
    return Array.from(words[0]).slice(0, 2).join("").toUpperCase();
  }

  return words
    .slice(0, 2)
    .map((word) => Array.from(word)[0])
    .join("")
    .toUpperCase();
}
