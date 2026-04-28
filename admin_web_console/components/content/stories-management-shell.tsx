"use client";

import { useDeferredValue, useMemo, useState } from "react";
import {
  formatAdminDate,
  localizeAdminFreshnessNote,
  localizeAdminLabel,
  localizeAdminMessage,
} from "@/lib/admin/admin-localization";
import {
  CONTENT_ADMIN_STATES,
  CONTENT_ADMIN_STATE_CLASS_MAP,
  type ContentAdminState,
  type StoryModerationSnapshot,
} from "../../lib/content/content-models";
import { ContentActionCell } from "./content-action-cell";
import {
  FilterField,
  FilterSelect,
  FilterTextInput,
  FilterToolbar,
} from "../shared/filter-toolbar";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";

const STATE_FILTER_OPTIONS: { value: ContentAdminState | "all"; label: string }[] = [
  { value: "all", label: "كل الحالات" },
  { value: "pending", label: "قيد المراجعة" },
  { value: "approved", label: "معتمد" },
  { value: "rejected", label: "مرفوض" },
  { value: "flagged", label: "مبلّغ عنه" },
  { value: "paused", label: "موقوف" },
];

export function StoriesManagementShell({
  snapshot,
  canModerate,
}: {
  snapshot: StoryModerationSnapshot;
  canModerate: boolean;
}) {
  const localizedSource = localizeAdminLabel(snapshot.source);
  const [searchTerm, setSearchTerm] = useState("");
  const [stateFilter, setStateFilter] = useState<ContentAdminState | "all">("all");
  const deferredSearchTerm = useDeferredValue(searchTerm);

  const filteredItems = useMemo(() => {
    return snapshot.items.filter((s) => {
      const matchesSearch =
        s.caption.toLowerCase().includes(deferredSearchTerm.toLowerCase()) ||
        s.id.toLowerCase().includes(deferredSearchTerm.toLowerCase()) ||
        (s.venueName ?? s.venueId).toLowerCase().includes(
          deferredSearchTerm.toLowerCase(),
        );
      const matchesState = stateFilter === "all" || s.adminState === stateFilter;
      return matchesSearch && matchesState;
    });
  }, [snapshot.items, deferredSearchTerm, stateFilter]);

  return (
    <section className="card media-center-shell" data-testid="stories-management-shell" dir="rtl" lang="ar">
      <p className="muted-text">
        راجع القصص التي تظهر للمستخدمين واتخذ قرارًا واضحًا حسب صلاحيتك. لا
        تتغير حالة القصة أو ترويجها إلا عبر الخدمة الآمنة.
      </p>

      <div className="media-center-summary-grid" data-testid="stories-summary-grid">
        <div className="media-center-summary-item">
          <span className="muted-text">تم الإنشاء في</span>
          <strong>{formatAdminDate(snapshot.generatedAt)}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">مصدر البيانات</span>
          <strong>{localizedSource}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">الحالة</span>
          <strong>{localizeAdminLabel(snapshot.state)}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">عدد القصص</span>
          <strong>{snapshot.items.length}</strong>
        </div>
      </div>

      <div className="media-center-state-note" data-testid="stories-source-note">
        <p className="muted-text">مصدر البيانات: {localizedSource}</p>
        <p className="muted-text">حالة البيانات: {localizeAdminFreshnessNote(snapshot.freshnessNote)}</p>
        <p className="muted-text">
          الخيارات الحالية: الحالة=
          {snapshot.filtersApplied.statuses.map((entry) => localizeAdminLabel(entry)).join("، ") || "الكل"}؛ الجهة=
          {snapshot.filtersApplied.venueId ?? "الكل"}؛ العدد الأقصى={snapshot.filtersApplied.limit}
        </p>
      </div>

      {snapshot.state !== "success" && snapshot.message ? (
        <p className="status-warning">{localizeAdminMessage(snapshot.message)}</p>
      ) : null}

      <FilterToolbar className="media-center-filter-row">
        <FilterField label="بحث" className="media-center-filter-field">
          <FilterTextInput
            className="media-center-filter-input"
            type="search"
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
            placeholder="ابحث بنص القصة أو الجهة أو رقم القصة"
            data-testid="stories-search-input"
          />
        </FilterField>

        <FilterField label="الحالة" className="media-center-filter-field">
          <FilterSelect
            className="media-center-filter-select"
            value={stateFilter}
            onChange={(e) =>
              setStateFilter(e.target.value as ContentAdminState | "all")
            }
            data-testid="stories-state-filter"
          >
            {STATE_FILTER_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </FilterSelect>
        </FilterField>
      </FilterToolbar>

      {snapshot.state === "unavailable" ? (
        <p className="finance-read-inline-unavailable" role="alert" data-testid="stories-unavailable">
          {localizeAdminMessage(snapshot.message) ?? "مصدر القصص غير متاح."}
        </p>
      ) : snapshot.state === "empty" ? (
        <p data-testid="stories-empty">
          {snapshot.message ?? "لا توجد قصص للعرض حاليًا."}
        </p>
      ) : filteredItems.length === 0 ? (
        <p data-testid="stories-filter-empty">
          لا توجد قصص تطابق البحث والخيارات الحالية.
        </p>
      ) : (
        <DataTable testId="stories-table">
            <thead>
              <tr>
                <th>النص</th>
                <th>الجهة</th>
                <th>حالة القصة</th>
                <th>نشط</th>
                <th>مروّج</th>
                <th>تاريخ الإنشاء</th>
                {canModerate ? <th>الخيارات</th> : null}
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.id} data-testid={`story-row-${item.id}`}>
                  <td>
                    <div className="media-center-cell">
                      <strong>
                        {item.caption.slice(0, 50)}
                        {item.caption.length > 50 ? "..." : ""}
                      </strong>
                      <span className="muted-text">{item.id}</span>
                    </div>
                  </td>
                  <td>{item.venueName ?? item.venueId}</td>
                  <td>
                    <StatusBadge
                      className={CONTENT_ADMIN_STATE_CLASS_MAP[item.adminState] ?? "status-neutral"}
                    >
                      {CONTENT_ADMIN_STATES[item.adminState] ?? item.adminState}
                    </StatusBadge>
                  </td>
                  <td>{item.isActive ? "نعم" : "لا"}</td>
                  <td>
                    {item.isPromoted ? (
                      <StatusBadge tone="success" title="يتم التحكم به عبر الخدمة الآمنة">
                        مروّج
                        {item.promotedUntil
                          ? ` حتى ${formatAdminDate(item.promotedUntil, { dateOnly: true })}`
                          : ""}
                      </StatusBadge>
                    ) : (
                      <span className="muted-text">—</span>
                    )}
                  </td>
                  <td>{formatAdminDate(item.createdAt)}</td>
                  {canModerate ? (
                    <td>
                      <ContentActionCell
                        item={item}
                        targetType="story"
                        canModerate={canModerate}
                      />
                    </td>
                  ) : null}
                </tr>
              ))}
            </tbody>
          </DataTable>
      )}

      <div className="media-center-non-goals" data-testid="stories-non-goals">
        <p className="muted-text">
          إذا تعذر الاتصال بالخدمة أو كانت البيانات قديمة، تظهر الصفحة ذلك
          بوضوح بدل إظهار نجاح غير حقيقي.
        </p>
      </div>
    </section>
  );
}
