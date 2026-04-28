export default function AdminReversalsLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل طلبات عكس العمليات</h1>
        <p className="status-note">
          يتم تجهيز طلبات العكس التي تحتاج إلى اعتماد.
        </p>
      </article>
    </div>
  );
}
