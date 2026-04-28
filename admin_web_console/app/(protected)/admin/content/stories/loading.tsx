export default function AdminStoriesLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل القصص</h1>
        <p className="status-note">
          يتم تجهيز القصص وحالاتها والخيارات المتاحة حسب الصلاحية.
        </p>
      </article>
    </div>
  );
}
