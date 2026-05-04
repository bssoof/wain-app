export default function AdminDashboardLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل النظرة العامة</h1>
        <p className="status-note">
          يتم تجهيز المؤشرات التشغيلية وحالة التنبيهات.
        </p>
      </article>
    </div>
  );
}
