"use client";

import Link from "next/link";
import { useEffect } from "react";

type AdminConfigErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function AdminConfigError({
  error,
  reset,
}: AdminConfigErrorProps) {
  useEffect(() => {
    console.error("[admin][config][route-error]", error);
  }, [error]);

  return (
    <div className="admin-page-shell" role="alert" aria-live="assertive">
      <article className="card">
        <h1>تعذر تحميل إدارة الإعدادات</h1>
        <p className="status-note">
          حدث خطأ أثناء تجهيز سطح الحوكمة. يمكنك إعادة المحاولة أو الرجوع إلى لوحة
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
