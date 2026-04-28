export default function AdminWalletAuditLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل سجل المحفظة</h1>
        <p className="status-note">
          يتم تجهيز قيود المحفظة وحالات إجراءات العكس.
        </p>
      </article>
    </div>
  );
}
