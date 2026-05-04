export default function AdminReadinessLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل حالة النظام</h1>
        <p className="status-note">
          يتم تجهيز تقرير حالة الخدمات المرتبطة.
        </p>
      </article>
    </div>
  );
}
