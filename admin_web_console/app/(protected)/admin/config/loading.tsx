export default function AdminConfigLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل إدارة الإعدادات</h1>
        <p className="status-note">
          يتم تجهيز لقطة الحوكمة وسجل حالات النشر والاسترجاع.
        </p>
      </article>
    </div>
  );
}
