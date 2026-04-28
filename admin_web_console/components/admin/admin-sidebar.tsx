"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";

import type { AdminSession } from "@/lib/auth/guard-api";
import {
  getVisibleNavigationRouteGroups,
  type AdminSidebarGroupKey,
} from "@/lib/navigation/admin-route-map";

type AdminSidebarProps = {
  session: AdminSession;
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

export function AdminSidebar({ session }: AdminSidebarProps) {
  const pathname = usePathname();
  const router = useRouter();
  const routeGroups = getVisibleNavigationRouteGroups(session);
  const hoverIntentTimers = useRef<Map<string, ReturnType<typeof setTimeout>>>(
    new Map(),
  );
  const [isNarrowViewport, setIsNarrowViewport] = useState(false);
  const [collapsedGroups, setCollapsedGroups] =
    useState<Record<AdminSidebarGroupKey, boolean>>(buildExpandedGroupState);

  const activeGroupKey = useMemo(() => {
    const activeGroup = routeGroups.find((group) =>
      group.routes.some((route) => isRouteActive(pathname, route.path)),
    );

    return activeGroup?.key ?? null;
  }, [pathname, routeGroups]);

  useEffect(() => {
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
    if (!isNarrowViewport) {
      setCollapsedGroups(buildExpandedGroupState());
      return;
    }

    setCollapsedGroups(buildCollapsedStateForActiveGroup(activeGroupKey));
  }, [activeGroupKey, isNarrowViewport]);

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

  return (
    <aside className="admin-sidebar">
      <div className="admin-sidebar-brand">
        <h1>إدارة وين</h1>
        <p>لوحة التشغيل الإدارية</p>
      </div>

      <nav className="admin-sidebar-nav" aria-label="تنقل الإدارة">
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
                  return (
                    <Link
                      key={route.key}
                      href={route.path}
                      prefetch={false}
                      className={active ? "admin-nav-link active" : "admin-nav-link"}
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
                      <span>{route.title}</span>
                    </Link>
                  );
                })}
              </div>
            </section>
          );
        })}
      </nav>
    </aside>
  );
}
