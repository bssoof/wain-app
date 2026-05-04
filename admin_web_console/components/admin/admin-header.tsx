"use client";

import { useRouter } from "next/navigation";
import { signOut } from "firebase/auth";
import { auth } from "@/lib/firebase/client";
import type { AdminSession } from "@/lib/auth/guard-api";
import { canRenderAction } from "@/lib/auth/guard-api";
import { localizeAdminLabel } from "@/lib/admin/admin-localization";

type AdminHeaderProps = {
  session: AdminSession;
};

export function AdminHeader({ session }: AdminHeaderProps) {
  const router = useRouter();
  const canUseSignOutAction = canRenderAction(session, "shell.sign_out");
  const visibleAdminName = formatAdminDisplayName(session);

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
      <div>
        <h2>لوحة التحكم الإدارية</h2>
        <p>
          مسجّل الدخول: <strong>{visibleAdminName}</strong>
        </p>
      </div>
      <div className="admin-header-actions">
        <button type="button" onClick={handleSignOut} disabled={!canUseSignOutAction}>
          تسجيل الخروج
        </button>
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
