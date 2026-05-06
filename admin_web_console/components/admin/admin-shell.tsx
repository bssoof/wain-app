"use client";

import { useEffect, useMemo, useState, type ReactNode } from "react";
import { usePathname, useRouter } from "next/navigation";

import type { AdminSession } from "@/lib/auth/guard-api";
import {
  buildAdminWarmupStorageKey,
  getAdminWarmupPolicy,
} from "@/lib/navigation/admin-warmup-policy";
import { ADMIN_ROUTE_MAP } from "@/lib/navigation/admin-route-map";
import type { HeaderEnvironment } from "@/components/admin/header/header-env-badge";
import type { HeaderBreadcrumbItem } from "@/components/admin/header/header-breadcrumb";

import { AdminBanner } from "@/components/admin/admin-banner";
import { AdminHeader } from "@/components/admin/admin-header";
import {
  AdminSidebar,
  type AdminSidebarDesktopMode,
  type AdminSidebarMode,
} from "@/components/admin/admin-sidebar";
import { ToastViewport } from "@/components/shared/ui/toast";

type AdminShellProps = {
  session: AdminSession;
  children: ReactNode;
};

const SIDEBAR_MODE_STORAGE_KEY = "wain.admin.sidebarMode";
const ADMIN_SHELL_MOBILE_QUERY = "(max-width: 1023px)";

export function AdminShell({ session, children }: AdminShellProps) {
  const pathname = usePathname();
  const router = useRouter();
  const isMobile = useIsMobile();
  const [sidebarMode, setSidebarMode] = useState<AdminSidebarDesktopMode>(() =>
    readStoredSidebarMode(),
  );
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [environment, setEnvironment] = useState<HeaderEnvironment>("unknown");

  const warmupPolicy = useMemo(() => {
    return getAdminWarmupPolicy(session, { pathname });
  }, [pathname, session]);

  const breadcrumb = useMemo(() => {
    return computeBreadcrumb(pathname);
  }, [pathname]);

  const effectiveSidebarMode: AdminSidebarMode = isMobile ? "drawer" : sidebarMode;

  useEffect(() => {
    setEnvironment(detectEnvironment());
  }, []);

  useEffect(() => {
    window.localStorage.setItem(SIDEBAR_MODE_STORAGE_KEY, sidebarMode);
  }, [sidebarMode]);

  useEffect(() => {
    setDrawerOpen(false);
  }, [pathname]);

  useEffect(() => {
    if (!pathname?.startsWith("/admin")) {
      return;
    }

    const storageKey = buildAdminWarmupStorageKey(session.uid);
    if (window.sessionStorage.getItem(storageKey) === "1") {
      return;
    }

    let cancelled = false;
    let timeoutHandle: ReturnType<typeof setTimeout> | null = null;
    let idleHandle: number | null = null;

    const runWarmup = () => {
      if (cancelled) {
        return;
      }
      if (window.sessionStorage.getItem(storageKey) === "1") {
        return;
      }

      window.sessionStorage.setItem(storageKey, "1");

      for (const path of warmupPolicy.prefetchPaths) {
        router.prefetch(path);
      }

      fetch("/api/admin/warmup", {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ routeKeys: warmupPolicy.warmupRouteKeys }),
      }).catch(() => undefined);
    };

    const idleWindow = window as Window & {
      requestIdleCallback?: (callback: IdleRequestCallback, options?: IdleRequestOptions) => number;
      cancelIdleCallback?: (handle: number) => void;
    };

    if (typeof idleWindow.requestIdleCallback === "function") {
      idleHandle = idleWindow.requestIdleCallback(() => {
        runWarmup();
      }, { timeout: 1500 });
    } else {
      timeoutHandle = setTimeout(runWarmup, 200);
    }

    return () => {
      cancelled = true;
      if (timeoutHandle) {
        clearTimeout(timeoutHandle);
      }
      if (
        idleHandle !== null &&
        typeof idleWindow.cancelIdleCallback === "function"
      ) {
        idleWindow.cancelIdleCallback(idleHandle);
      }
    };
  }, [pathname, router, session.uid, warmupPolicy]);

  const handleQuickNavigate = (path: string) => {
    router.push(path);
    setDrawerOpen(false);
  };

  return (
    <div
      className={`admin-shell admin-shell-root admin-shell--${effectiveSidebarMode}`}
      dir="rtl"
      lang="ar"
    >
      <AdminSidebar
        session={session}
        mode={effectiveSidebarMode}
        onModeChange={setSidebarMode}
        open={drawerOpen}
        onOpenChange={setDrawerOpen}
      />
      <div className="admin-shell__main admin-shell-main">
        <AdminHeader
          session={session}
          breadcrumb={breadcrumb}
          environment={environment}
          menuControls={isMobile ? "admin-sidebar-drawer" : undefined}
          menuExpanded={isMobile ? drawerOpen : undefined}
          onMenuClick={isMobile ? () => setDrawerOpen(true) : undefined}
          onQuickNavigate={handleQuickNavigate}
        />
        <AdminBanner />
        <main className="admin-shell__content admin-shell-content">{children}</main>
      </div>
      <ToastViewport />
    </div>
  );
}

function readStoredSidebarMode(): AdminSidebarDesktopMode {
  if (typeof window === "undefined") {
    return "expanded";
  }

  const storedMode = window.localStorage.getItem(SIDEBAR_MODE_STORAGE_KEY);
  return storedMode === "compact" || storedMode === "expanded"
    ? storedMode
    : "expanded";
}

function useIsMobile(): boolean {
  const [isMobile, setIsMobile] = useState(false);

  useEffect(() => {
    if (typeof window.matchMedia !== "function") {
      return;
    }

    const mediaQuery = window.matchMedia(ADMIN_SHELL_MOBILE_QUERY);
    const updateMatches = () => {
      setIsMobile(mediaQuery.matches);
    };

    updateMatches();

    if (typeof mediaQuery.addEventListener === "function") {
      mediaQuery.addEventListener("change", updateMatches);
      return () => mediaQuery.removeEventListener("change", updateMatches);
    }

    mediaQuery.addListener(updateMatches);
    return () => mediaQuery.removeListener(updateMatches);
  }, []);

  return isMobile;
}

function computeBreadcrumb(pathname: string): HeaderBreadcrumbItem[] {
  if (!pathname || pathname === "/admin") {
    return [{ label: "الإدارة" }];
  }

  const matchedRoute = ADMIN_ROUTE_MAP
    .filter(
      (route) => pathname === route.path || pathname.startsWith(`${route.path}/`),
    )
    .sort((left, right) => right.path.length - left.path.length)[0];

  const breadcrumb: HeaderBreadcrumbItem[] = [{ label: "الإدارة", href: "/admin" }];

  if (!matchedRoute) {
    const segments = pathname.split("/").filter(Boolean).slice(1);
    segments.forEach((segment, index) => {
      const href = `/admin/${segments.slice(0, index + 1).join("/")}`;
      breadcrumb.push({
        label: formatPathSegment(segment),
        href: index === segments.length - 1 ? undefined : href,
      });
    });
    return breadcrumb;
  }

  breadcrumb.push({
    label: matchedRoute.title,
    href: pathname === matchedRoute.path ? undefined : matchedRoute.path,
  });

  const remainder = pathname
    .slice(matchedRoute.path.length)
    .split("/")
    .filter(Boolean);

  remainder.forEach((segment, index) => {
    const href = `${matchedRoute.path}/${remainder.slice(0, index + 1).join("/")}`;
    breadcrumb.push({
      label: formatPathSegment(segment),
      href: index === remainder.length - 1 ? undefined : href,
    });
  });

  return breadcrumb;
}

function formatPathSegment(segment: string): string {
  try {
    return decodeURIComponent(segment);
  } catch {
    return segment;
  }
}

function detectEnvironment(): HeaderEnvironment {
  if (typeof window === "undefined") {
    return "unknown";
  }

  const hostname = window.location.hostname;
  if (hostname === "localhost" || hostname === "127.0.0.1") {
    return "local";
  }
  if (hostname.includes("--")) {
    return "preview";
  }
  if (hostname.startsWith("wain-admin.")) {
    return "production";
  }
  return "unknown";
}
