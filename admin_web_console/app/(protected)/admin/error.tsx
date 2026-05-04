"use client";

import Link from "next/link";
import { useEffect } from "react";

type ProtectedAdminErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function ProtectedAdminError({
  error,
  reset,
}: ProtectedAdminErrorProps) {
  useEffect(() => {
    console.error("[admin][route-error]", error);
  }, [error]);

  return (
    <div className="admin-page-shell" role="alert" aria-live="assertive">
      <article className="card">
        <h1>تعذر تحميل الصفحة الإدارية</h1>
        <p className="status-note">
          حدث خطأ غير متوقع أثناء تجهيز الصفحة. يمكنك إعادة المحاولة أو العودة إلى لوحة
          المؤشرات.
        </p>

        {error.digest ? (
          <p className="muted-text">معرّف التتبع: {error.digest}</p>
        ) : null}

        <div className="command-actions__row">
          <button type="button" className="action-button" onClick={reset}>
            إعادة المحاولة
          </button>
          <Link href="/admin/dashboard" className="action-button action-button-secondary">
            العودة إلى النظرة العامة
          </Link>
        </div>
      </article>
    </div>
  );
}
