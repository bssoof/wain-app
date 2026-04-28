"use client";

import { useEffect, useMemo, type ReactNode } from "react";
import { usePathname, useRouter } from "next/navigation";

import type { AdminSession } from "@/lib/auth/guard-api";
import {
  buildAdminWarmupStorageKey,
  getAdminWarmupPolicy,
} from "@/lib/navigation/admin-warmup-policy";

import { AdminHeader } from "@/components/admin/admin-header";
import { AdminSidebar } from "@/components/admin/admin-sidebar";

type AdminShellProps = {
  session: AdminSession;
  children: ReactNode;
};

export function AdminShell({ session, children }: AdminShellProps) {
  const pathname = usePathname();
  const router = useRouter();

  const warmupPolicy = useMemo(() => {
    return getAdminWarmupPolicy(session, { pathname });
  }, [pathname, session]);

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

  return (
    <div className="admin-shell-root" dir="rtl" lang="ar">
      <AdminSidebar session={session} />
      <main className="admin-shell-main">
        <AdminHeader session={session} />
        <section className="admin-shell-content">{children}</section>
      </main>
    </div>
  );
}
