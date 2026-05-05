"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { createPortal } from "react-dom";
import { Search } from "lucide-react";
import type { KeyboardEvent, ChangeEvent } from "react";
import type { LucideIcon } from "lucide-react";

import { IconButton } from "@/components/shared/ui/icon-button";

export type HeaderQuickSearchRoute = {
  path: string;
  label: string;
  icon?: LucideIcon;
};

export type HeaderQuickSearchProps = {
  routes: HeaderQuickSearchRoute[];
  onNavigate: (path: string) => void;
};

export function HeaderQuickSearch({
  routes,
  onNavigate,
}: HeaderQuickSearchProps): JSX.Element {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [activeIndex, setActiveIndex] = useState(0);
  const inputRef = useRef<HTMLInputElement | null>(null);

  const filteredRoutes = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase();
    if (!normalizedQuery) {
      return routes;
    }

    return routes.filter((route) => {
      const label = route.label.toLowerCase();
      const path = route.path.toLowerCase();
      return label.includes(normalizedQuery) || path.includes(normalizedQuery);
    });
  }, [query, routes]);

  useEffect(() => {
    const handleKeydown = (event: globalThis.KeyboardEvent) => {
      const key = event.key.toLowerCase();
      if ((event.metaKey || event.ctrlKey) && key === "k") {
        event.preventDefault();
        setOpen(true);
        return;
      }

      if (event.key === "Escape") {
        setOpen(false);
      }
    };

    document.addEventListener("keydown", handleKeydown);
    return () => {
      document.removeEventListener("keydown", handleKeydown);
    };
  }, []);

  useEffect(() => {
    setActiveIndex(0);
  }, [query, open]);

  useEffect(() => {
    if (!open) {
      return;
    }

    window.setTimeout(() => {
      inputRef.current?.focus();
    }, 0);
  }, [open]);

  const closeSearch = () => {
    setOpen(false);
  };

  const selectRoute = (route: HeaderQuickSearchRoute) => {
    onNavigate(route.path);
    closeSearch();
  };

  const handleInputChange = (event: ChangeEvent<HTMLInputElement>) => {
    setQuery(event.target.value);
  };

  const handleInputKeyDown = (event: KeyboardEvent<HTMLInputElement>) => {
    if (event.key === "Escape") {
      event.preventDefault();
      closeSearch();
      return;
    }

    if (filteredRoutes.length === 0) {
      return;
    }

    if (event.key === "ArrowDown") {
      event.preventDefault();
      setActiveIndex((current) => (current + 1) % filteredRoutes.length);
      return;
    }

    if (event.key === "ArrowUp") {
      event.preventDefault();
      setActiveIndex((current) =>
        current === 0 ? filteredRoutes.length - 1 : current - 1,
      );
      return;
    }

    if (event.key === "Enter") {
      event.preventDefault();
      const activeRoute = filteredRoutes[activeIndex];
      if (activeRoute) {
        selectRoute(activeRoute);
      }
    }
  };

  const activeResultId =
    filteredRoutes.length > 0 ? `header-quick-search-result-${activeIndex}` : undefined;

  const dialog = open
    ? createPortal(
        <div
          className="header-quick-search-backdrop"
          data-testid="header-quick-search-backdrop"
          onClick={(event) => {
            if (event.target === event.currentTarget) {
              closeSearch();
            }
          }}
        >
          <div
            className="header-quick-search-dialog"
            role="dialog"
            aria-modal="true"
            aria-label="بحث سريع"
          >
            <input
              ref={inputRef}
              className="header-quick-search-input"
              type="search"
              value={query}
              onChange={handleInputChange}
              onKeyDown={handleInputKeyDown}
              aria-label="بحث في صفحات الإدارة"
              aria-controls="header-quick-search-results"
              aria-activedescendant={activeResultId}
              placeholder="ابحث عن صفحة أو مسار"
            />
            <ul
              className="header-quick-search-list"
              id="header-quick-search-results"
              role="listbox"
            >
              {filteredRoutes.length === 0 ? (
                <li className="header-quick-search-empty" role="status">
                  لا توجد نتائج
                </li>
              ) : (
                filteredRoutes.map((route, index) => {
                  const Icon = route.icon;
                  const isActive = index === activeIndex;

                  return (
                    <li
                      id={`header-quick-search-result-${index}`}
                      className={
                        isActive
                          ? "header-quick-search-item header-quick-search-item--active"
                          : "header-quick-search-item"
                      }
                      key={route.path}
                      role="option"
                      aria-selected={isActive}
                      onMouseEnter={() => setActiveIndex(index)}
                      onMouseDown={(event) => event.preventDefault()}
                      onClick={() => selectRoute(route)}
                    >
                      {Icon ? <Icon aria-hidden="true" size={16} strokeWidth={2} /> : null}
                      <span>{route.label}</span>
                      <small>{route.path}</small>
                    </li>
                  );
                })
              )}
            </ul>
          </div>
        </div>,
        document.body,
      )
    : null;

  return (
    <>
      <IconButton
        className="header-quick-search-trigger"
        icon={Search}
        label="بحث"
        onClick={() => setOpen((current) => !current)}
        aria-haspopup="dialog"
        aria-expanded={open}
      />
      {dialog}
    </>
  );
}
