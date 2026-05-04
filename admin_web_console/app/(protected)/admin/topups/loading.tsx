export default function AdminTopupsLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل طلبات الشحن</h1>
        <p className="status-note">
          يتم تجهيز طلبات الشحن وحالات الاعتماد المتاحة.
        </p>
      </article>
    </div>
  );
}
