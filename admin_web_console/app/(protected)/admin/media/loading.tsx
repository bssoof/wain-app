export default function AdminMediaLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل الصور والملفات</h1>
        <p className="status-note">
          يتم تجهيز الجرد وحالات المرجع والإجراءات المتاحة.
        </p>
      </article>
    </div>
  );
}
