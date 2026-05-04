"use client";

import Link from "next/link";
import { useEffect } from "react";

type AdminTopupsErrorProps = {
  error: Error & { digest?: string };
  reset: () => void;
};

export default function AdminTopupsError({
  error,
  reset,
}: AdminTopupsErrorProps) {
  useEffect(() => {
    console.error("[admin][topups][route-error]", error);
  }, [error]);

  return (
    <div className="admin-page-shell" role="alert" aria-live="assertive">
      <article className="card">
        <h1>تعذر تحميل طلبات الشحن</h1>
        <p className="status-note">
          حدث خطأ أثناء تجهيز بيانات طلبات الشحن. يمكنك إعادة المحاولة أو الرجوع إلى
          النظرة العامة.
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
