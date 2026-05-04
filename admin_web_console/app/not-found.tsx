import Link from "next/link";

export default function NotFoundPage() {
  return (
    <main className="admin-public-page" dir="rtl" lang="ar">
      <section className="admin-card">
        <span className="admin-card__eyebrow">404</span>
        <h1>الصفحة غير موجودة</h1>
        <p className="admin-card__description">
          المسار الذي طلبته غير متاح أو تم نقله. ارجع إلى لوحة التحكم أو افتح إحدى
          صفحات الإدارة المباشرة.
        </p>
        <div className="admin-card__actions">
          <Link className="admin-link-button admin-link-button--primary" href="/admin/dashboard">
            الذهاب إلى لوحة التحكم
          </Link>
          <Link className="admin-link-button" href="/admin/media">
            فتح الصور والملفات
          </Link>
        </div>
      </section>
    </main>
  );
}
