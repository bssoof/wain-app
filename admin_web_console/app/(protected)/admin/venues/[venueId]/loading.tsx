export default function AdminVenueWorkspaceLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل تفاصيل الجهة</h1>
        <p className="status-note">
          يتم تجهيز بيانات الجهة والأقسام المرتبطة بها.
        </p>
      </article>
    </div>
  );
}
