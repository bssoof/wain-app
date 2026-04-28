export default function AdminReviewsLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل المراجعات</h1>
        <p className="status-note">
          يتم تجهيز قائمة المراجعات وخيارات القرار المتاحة.
        </p>
      </article>
    </div>
  );
}
