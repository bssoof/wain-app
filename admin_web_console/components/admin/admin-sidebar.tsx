"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { PanelLeftClose, PanelLeftOpen } from "lucide-react";

import type { AdminSession } from "@/lib/auth/guard-api";
import {
  getVisibleNavigationRouteGroups,
  type AdminSidebarGroupKey,
} from "@/lib/navigation/admin-route-map";
import { IconButton } from "@/components/shared/ui/icon-button";
import { Tooltip } from "@/components/shared/ui/tooltip";

export type AdminSidebarMode = "expanded" | "compact" | "drawer";
export type AdminSidebarDesktopMode = Exclude<AdminSidebarMode, "drawer">;

export type AdminSidebarProps = {
  session: AdminSession;
  mode?: AdminSidebarMode;
  onModeChange?: (next: AdminSidebarDesktopMode) => void;
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
};

const SIDEBAR_COLLAPSE_MEDIA_QUERY = "(max-width: 980px)";
const HOVER_INTENT_PREFETCH_DELAY_MS = 120;

function buildExpandedGroupState(): Record<AdminSidebarGroupKey, boolean> {
  return {
    finance: false,
    content: false,
    system: false,
  };
}

function buildCollapsedStateForActiveGroup(
  activeGroupKey: AdminSidebarGroupKey | null,
): Record<AdminSidebarGroupKey, boolean> {
  if (!activeGroupKey) {
    return buildExpandedGroupState();
  }

  return {
    finance: activeGroupKey !== "finance",
    content: activeGroupKey !== "content",
    system: activeGroupKey !== "system",
  };
}

function isRouteActive(pathname: string, routePath: string): boolean {
  if (pathname === routePath) {
    return true;
  }

  return pathname.startsWith(`${routePath}/`);
}

function joinClassNames(...classNames: Array<string | false | null | undefined>): string {
  return classNames.filter(Boolean).join(" ");
}

export function AdminSidebar({
  session,
  mode = "expanded",
  onModeChange,
  open = false,
  onOpenChange,
}: AdminSidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const routeGroups = getVisibleNavigationRouteGroups(session);
  const hoverIntentTimers = useRef<Map<string, ReturnType<typeof setTimeout>>>(
    new Map(),
  );
  const firstLinkRef = useRef<HTMLAnchorElement | null>(null);
  const [isNarrowViewport, setIsNarrowViewport] = useState(false);
  const [collapsedGroups, setCollapsedGroups] =
    useState<Record<AdminSidebarGroupKey, boolean>>(buildExpandedGroupState);
  const isDrawerMode = mode === "drawer";
  const isCompactMode = mode === "compact";

  const activeGroupKey = useMemo(() => {
    const activeGroup = routeGroups.find((group) =>
      group.routes.some((route) => isRouteActive(pathname, route.path)),
    );

    return activeGroup?.key ?? null;
  }, [pathname, routeGroups]);

  useEffect(() => {
    if (typeof window.matchMedia !== "function") {
      return;
    }

    const mediaQuery = window.matchMedia(SIDEBAR_COLLAPSE_MEDIA_QUERY);

    const updateMatches = () => {
      setIsNarrowViewport(mediaQuery.matches);
    };

    updateMatches();

    if (typeof mediaQuery.addEventListener === "function") {
      mediaQuery.addEventListener("change", updateMatches);
      return () => {
        mediaQuery.removeEventListener("change", updateMatches);
      };
    }

    mediaQuery.addListener(updateMatches);
    return () => {
      mediaQuery.removeListener(updateMatches);
    };
  }, []);

  useEffect(() => {
    if (isDrawerMode) {
      return;
    }

    if (!isNarrowViewport) {
      setCollapsedGroups(buildExpandedGroupState());
      return;
    }

    setCollapsedGroups(buildCollapsedStateForActiveGroup(activeGroupKey));
  }, [activeGroupKey, isDrawerMode, isNarrowViewport]);

  useEffect(() => {
    if (!isDrawerMode || !open) {
      return;
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onOpenChange?.(false);
      }
    };

    firstLinkRef.current?.focus();
    window.addEventListener("keydown", handleKeyDown);

    return () => {
      window.removeEventListener("keydown", handleKeyDown);
    };
  }, [isDrawerMode, onOpenChange, open]);

  useEffect(() => {
    const timers = hoverIntentTimers.current;
    return () => {
      for (const timer of timers.values()) {
        clearTimeout(timer);
      }
      timers.clear();
    };
  }, []);

  const toggleGroup = (groupKey: AdminSidebarGroupKey) => {
    if (!isNarrowViewport) {
      return;
    }

    setCollapsedGroups((previous) => ({
      ...previous,
      [groupKey]: !previous[groupKey],
    }));
  };

  const scheduleHoverIntentPrefetch = (
    path: string,
    prefetchMode: string,
    active: boolean,
  ) => {
    if (prefetchMode !== "hover-intent" || active) {
      return;
    }

    const timers = hoverIntentTimers.current;
    if (timers.has(path)) {
      return;
    }

    const timer = setTimeout(() => {
      timers.delete(path);
      router.prefetch(path);
    }, HOVER_INTENT_PREFETCH_DELAY_MS);
    timers.set(path, timer);
  };

  const cancelHoverIntentPrefetch = (path: string) => {
    const timer = hoverIntentTimers.current.get(path);
    if (!timer) {
      return;
    }

    clearTimeout(timer);
    hoverIntentTimers.current.delete(path);
  };

  const toggleSidebarMode = () => {
    onModeChange?.(isCompactMode ? "expanded" : "compact");
  };

  if (isDrawerMode && !open) {
    return null;
  }

  let renderedRouteIndex = 0;

  const sidebar = (
    <aside
      id="admin-sidebar-drawer"
      aria-label={isDrawerMode ? "القائمة الجانبية" : undefined}
      aria-modal={isDrawerMode ? "true" : undefined}
      className={joinClassNames(
        "admin-sidebar",
        `admin-sidebar--${mode}`,
        isDrawerMode && "admin-sidebar--drawer-enter",
      )}
      role={isDrawerMode ? "dialog" : undefined}
    >
      <div className="admin-sidebar-brand">
        <h1>إدارة وين</h1>
        <p>لوحة التشغيل الإدارية</p>
      </div>

      <nav className="admin-sidebar-nav admin-sidebar__list" aria-label="تنقل الإدارة">
        {routeGroups.length === 0 ? (
          <p className="admin-sidebar-empty">لا توجد مسارات متاحة لهذه الجلسة بعد.</p>
        ) : null}

        {routeGroups.map((group) => {
          const groupIsActive = group.key === activeGroupKey;
          const linksCollapsed = isNarrowViewport ? collapsedGroups[group.key] : false;
          const groupLinksId = `admin-sidebar-group-${group.key}`;

          return (
            <section
              key={group.key}
              className={groupIsActive ? "admin-sidebar-group active" : "admin-sidebar-group"}
            >
              <button
                type="button"
                className={
                  groupIsActive
                    ? "admin-sidebar-group-toggle active"
                    : "admin-sidebar-group-toggle"
                }
                aria-expanded={!linksCollapsed}
                aria-controls={groupLinksId}
                onClick={() => toggleGroup(group.key)}
              >
                <span>{group.title}</span>
                <small>{linksCollapsed ? "إظهار" : "إخفاء"}</small>
              </button>

              <div
                id={groupLinksId}
                className={
                  linksCollapsed
                    ? "admin-sidebar-group-links collapsed"
                    : "admin-sidebar-group-links"
                }
              >
                {group.routes.map((route) => {
                  const active = isRouteActive(pathname, route.path);
                  const routeIndex = renderedRouteIndex;
                  renderedRouteIndex += 1;
                  const RouteIcon = route.icon;
                  const icon = (
                    <span className="admin-sidebar__item-icon-wrap">
                      <RouteIcon
                        aria-hidden="true"
                        className="admin-sidebar__item-icon"
                        data-testid={`admin-sidebar-icon-${route.key}`}
                        size={18}
                        strokeWidth={2}
                      />
                    </span>
                  );

                  return (
                    <Link
                      key={route.key}
                      ref={routeIndex === 0 ? firstLinkRef : undefined}
                      href={route.path}
                      prefetch={false}
                      aria-label={isCompactMode ? route.title : undefined}
                      className={joinClassNames(
                        "admin-nav-link",
                        "admin-sidebar__item",
                        active && "active",
                        active && "admin-sidebar__item--active",
                      )}
                      title={route.scopeNote}
                      aria-current={active ? "page" : undefined}
                      onPointerEnter={() =>
                        scheduleHoverIntentPrefetch(
                          route.path,
                          route.prefetchMode,
                          active,
                        )
                      }
                      onPointerLeave={() => cancelHoverIntentPrefetch(route.path)}
                      onFocus={() =>
                        scheduleHoverIntentPrefetch(
                          route.path,
                          route.prefetchMode,
                          active,
                        )
                      }
                      onBlur={() => cancelHoverIntentPrefetch(route.path)}
                    >
                      {isCompactMode ? (
                        <Tooltip content={route.title} side="left">
                          {icon}
                        </Tooltip>
                      ) : (
                        icon
                      )}
                      <span
                        aria-hidden={isCompactMode ? "true" : undefined}
                        className="admin-sidebar__item-label"
                      >
                        {route.title}
                      </span>
                    </Link>
                  );
                })}
              </div>
            </section>
          );
        })}
      </nav>

      {!isDrawerMode ? (
        <div className="admin-sidebar__toggle">
          <IconButton
            icon={isCompactMode ? PanelLeftOpen : PanelLeftClose}
            label={isCompactMode ? "توسيع القائمة الجانبية" : "طي القائمة الجانبية"}
            onClick={toggleSidebarMode}
            size="md"
            variant="ghost"
          />
        </div>
      ) : null}
    </aside>
  );

  if (!isDrawerMode) {
    return sidebar;
  }

  return (
    <>
      <div
        aria-hidden="true"
        className="admin-sidebar-drawer-backdrop"
        onClick={() => onOpenChange?.(false)}
      />
      {sidebar}
    </>
  );
}
