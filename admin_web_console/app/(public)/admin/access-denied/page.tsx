import Link from "next/link";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";

type AccessDeniedPageProps = {
  searchParams?: {
    route?: string;
  };
};

export default function AccessDeniedPage({ searchParams }: AccessDeniedPageProps) {
  const route = searchParams?.route ?? "غير معروف";
  const routeLabel = localizeAdminLabel(route);

  return (
    <main className="auth-page" dir="rtl" lang="ar">
      <section className="auth-card card">
        <h1>تم رفض الوصول</h1>
        <p>ليست لديك الصلاحية للوصول إلى هذا المسار الإداري.</p>
        <p className="status-note">المسار المطلوب: {routeLabel}</p>
        <div className="auth-links">
          <Link href="/admin/sign-in">العودة إلى تسجيل دخول الإدارة</Link>
        </div>
      </section>
    </main>
  );
}
