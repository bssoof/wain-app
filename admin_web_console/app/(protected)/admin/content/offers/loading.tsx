export default function AdminOffersLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل العروض</h1>
        <p className="status-note">
          يتم تجهيز العروض وحالاتها والخيارات المتاحة حسب الصلاحية.
        </p>
      </article>
    </div>
  );
}
