export default function ProtectedAdminLoading() {
  return (
    <div className="admin-page-shell" aria-busy="true" aria-live="polite">
      <article className="card">
        <h1>جاري تحميل لوحة الإدارة</h1>
        <p className="status-note">
          يتم تجهيز بيانات المسار الحالي. يرجى الانتظار لحظات.
        </p>
      </article>
    </div>
  );
}
