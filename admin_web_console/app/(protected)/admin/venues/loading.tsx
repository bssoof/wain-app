export default function AdminVenuesLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل قائمة الجهات</h1>
        <p className="status-note">
          يتم تجهيز الجهات وحالاتها وخيارات التعديل المتاحة.
        </p>
      </article>
    </div>
  );
}
