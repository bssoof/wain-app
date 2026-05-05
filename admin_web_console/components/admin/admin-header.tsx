"use client";

import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { Menu } from "lucide-react";
import { auth } from "@/lib/firebase/client";
import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";
import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import { ADMIN_ROUTE_MAP } from "@/lib/navigation/admin-route-map";

import {
  HeaderBreadcrumb,
  type HeaderBreadcrumbItem,
} from "@/components/admin/header/header-breadcrumb";
import {
  HeaderEnvironmentBadge,
  type HeaderEnvironment,
} from "@/components/admin/header/header-env-badge";
import { HeaderQuickSearch } from "@/components/admin/header/header-quick-search";
import { HeaderUserMenu } from "@/components/admin/header/header-user-menu";
import { IconButton } from "@/components/shared/ui/icon-button";

export type AdminHeaderProps = {
  session: AdminSession;
  breadcrumb?: HeaderBreadcrumbItem[];
  onQuickNavigate?: (path: string) => void;
  environment?: HeaderEnvironment;
  onMenuClick?: () => void;
};

const ADMIN_HEADER_SEARCH_ROUTES = ADMIN_ROUTE_MAP.map((route) => ({
  path: route.path,
  label: route.title,
}));

export function AdminHeader({
  session,
  breadcrumb,
  onQuickNavigate,
  environment = "unknown",
  onMenuClick,
}: AdminHeaderProps) {
  const router = useRouter();
  const canUseSignOutAction = canRenderAction(session, "shell.sign_out");
  const visibleAdminName = formatAdminDisplayName(session);
  const handleQuickNavigate = onQuickNavigate ?? ((path: string) => router.push(path));

  const handleSignOut = async () => {
    if (!canUseSignOutAction) return;
    try {
      if (auth.currentUser) {
        await signOut(auth);
      }

      await fetch("/api/admin/session", {
        method: "DELETE",
      });

      router.push("/admin/sign-in");
    } catch (e) {
      console.error("Failed to sign out:", e);
    }
  };

  return (
    <header className="admin-header">
      <div className="admin-header__start">
        {onMenuClick ? (
          <IconButton
            className="admin-header__menu-trigger"
            icon={Menu}
            label="فتح القائمة الجانبية"
            onClick={onMenuClick}
            size="md"
            variant="ghost"
          />
        ) : null}
        <HeaderBreadcrumb items={breadcrumb ?? []} />
      </div>
      <div className="admin-header__end">
        <HeaderQuickSearch
          routes={ADMIN_HEADER_SEARCH_ROUTES}
          onNavigate={handleQuickNavigate}
        />
        <HeaderEnvironmentBadge value={environment} />
        <HeaderUserMenu
          userName={visibleAdminName}
          userEmail={session.email}
          onSignOut={handleSignOut}
        />
      </div>
    </header>
  );
}

function formatAdminDisplayName(session: AdminSession): string {
  if (session.displayName) {
    const localizedName = localizeAdminLabel(session.displayName);
    return localizedName === "غير معروف" ? session.displayName : localizedName;
  }

  return session.email ?? session.uid;
}
