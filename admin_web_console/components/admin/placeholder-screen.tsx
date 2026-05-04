import type { AdminSession } from "@/lib/auth/guard-api";
import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import { canRenderAction } from "@/lib/auth/guard-api";
import type {
  AdminCapabilityKey,
  AdminRouteKey,
} from "@/lib/navigation/admin-contract";

type PlaceholderScreenProps = {
  title: string;
  scopeNote: string;
  routeKey: AdminRouteKey;
  session: AdminSession;
  routeCapability: AdminCapabilityKey | null;
  mutationCapabilities: AdminCapabilityKey[];
};

export function PlaceholderScreen({
  title,
  scopeNote,
  routeKey,
  session,
  routeCapability,
  mutationCapabilities,
}: PlaceholderScreenProps) {
  const localizedRouteKey = localizeAdminLabel(routeKey);
  const localizedRouteCapability = routeCapability
    ? localizeAdminLabel(routeCapability)
    : "لا يوجد";

  const routeCapabilityVisibility = routeCapability
    ? canRenderAction(session, routeCapability)
      ? "مسموح"
      : "مرفوض"
    : "غير مطلوب";

  const mutationCapabilityNotes =
    mutationCapabilities.length === 0
      ? "لا يوجد (سطح قراءة فقط)"
      : mutationCapabilities
          .map((capability) =>
            `${localizeAdminLabel(capability)}: ${canRenderAction(session, capability) ? "مسموح" : "مرفوض"}`,
          )
          .join("، ");

  return (
    <div className="admin-page-shell">
      <article className="card">
        <h1>{title}</h1>
        <p>{scopeNote}</p>
        <p className="status-note">
          التنفيذ التفصيلي لهذه الصفحة ما زال قيد الإكمال، والسطح الحالي مجرد هيكل تشغيلي.
        </p>
        <ul>
          <li>مفتاح المسار: {localizedRouteKey}</li>
          <li>صلاحية المسار: {localizedRouteCapability}</li>
          <li>حالة صلاحية المسار: {routeCapabilityVisibility}</li>
          <li>ملاحظات صلاحيات التعديل: {mutationCapabilityNotes}</li>
        </ul>
      </article>
    </div>
  );
}
