"use client";

import Link from "next/link";
import { useEffect } from "react";

type AdminVenueWorkspaceErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function AdminVenueWorkspaceError({
  error,
  reset,
}: AdminVenueWorkspaceErrorProps) {
  useEffect(() => {
    console.error("[admin][venue-workspace][route-error]", error);
  }, [error]);

  return (
    <div className="admin-page-shell" role="alert" aria-live="assertive">
      <article className="card">
        <h1>تعذر تحميل تفاصيل الجهة</h1>
        <p className="status-note">
          حدث خطأ أثناء تجهيز بيانات الجهة الحالية. يمكنك إعادة المحاولة أو العودة إلى
          قائمة الجهات.
        </p>

        {error.digest ? (
          <p className="muted-text">معرّف التتبع: {error.digest}</p>
        ) : null}

        <div className="command-actions__row">
          <button type="button" className="action-button" onClick={reset}>
            إعادة المحاولة
          </button>
          <Link href="/admin/venues" className="action-button action-button-secondary">
            العودة إلى الجهات
          </Link>
        </div>
      </article>
    </div>
  );
}
