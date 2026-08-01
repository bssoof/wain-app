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
  type OfferModerationSnapshot,
} from "../../lib/content/content-models";
import { ContentActionCell } from "./content-action-cell";
import {
  type ActiveFilterChip,
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

export function OffersManagementShell({
  snapshot,
  canModerate,
}: {
  snapshot: OfferModerationSnapshot;
  canModerate: boolean;
}) {
  const localizedSource = localizeAdminLabel(snapshot.source);
  const [searchTerm, setSearchTerm] = useState("");
  const [stateFilter, setStateFilter] = useState<ContentAdminState | "all">("all");
  const deferredSearchTerm = useDeferredValue(searchTerm);

  const filteredItems = useMemo(() => {
    return snapshot.items.filter((o) => {
      const matchesSearch =
        o.title.toLowerCase().includes(deferredSearchTerm.toLowerCase()) ||
        o.id.toLowerCase().includes(deferredSearchTerm.toLowerCase()) ||
        (o.venueName ?? o.venueId).toLowerCase().includes(
          deferredSearchTerm.toLowerCase(),
        );
      const matchesState = stateFilter === "all" || o.adminState === stateFilter;
      return matchesSearch && matchesState;
    });
  }, [snapshot.items, deferredSearchTerm, stateFilter]);

  const hasActiveFilter = searchTerm.trim().length > 0 || stateFilter !== "all";
  const activeFilters = useMemo<ActiveFilterChip[]>(
    () =>
      [
        searchTerm.trim().length > 0
          ? {
              key: "search",
              label: "بحث",
              value: searchTerm.trim(),
              onRemove: () => setSearchTerm(""),
            }
          : null,
        stateFilter !== "all"
          ? {
              key: "state",
              label: "الحالة",
              value: getStateFilterLabel(stateFilter),
              onRemove: () => setStateFilter("all"),
            }
          : null,
      ].filter((filter): filter is ActiveFilterChip => filter !== null),
    [searchTerm, stateFilter],
  );

  function resetFilters() {
    setSearchTerm("");
    setStateFilter("all");
  }

  return (
    <section className="card media-center-shell" data-testid="offers-management-shell" dir="rtl" lang="ar">
      <p className="muted-text">
        راجع العروض التي تظهر للمستخدمين واتخذ قرارًا واضحًا حسب صلاحيتك. لا
        تتغير حالة العرض أو تمييزه إلا عبر الخدمة الآمنة.
      </p>

      <div className="media-center-summary-grid" data-testid="offers-summary-grid">
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
          <span className="muted-text">عدد العروض</span>
          <strong>{snapshot.items.length}</strong>
        </div>
      </div>

      <div className="media-center-state-note" data-testid="offers-source-note">
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

      <FilterToolbar
        activeFilters={activeFilters}
        className="media-center-filter-row"
        onClearAll={hasActiveFilter ? resetFilters : undefined}
      >
        <FilterField label="بحث" className="media-center-filter-field">
          <FilterTextInput
            className="media-center-filter-input"
            type="search"
            value={searchTerm}
            onChange={(event) => setSearchTerm(event.target.value)}
            placeholder="ابحث بعنوان العرض أو الجهة أو رقم العرض"
            data-testid="offers-search-input"
          />
        </FilterField>

        <FilterField label="الحالة" className="media-center-filter-field">
          <FilterSelect
            className="media-center-filter-select"
            value={stateFilter}
            onChange={(e) =>
              setStateFilter(e.target.value as ContentAdminState | "all")
            }
            data-testid="offers-state-filter"
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
        <p className="finance-read-inline-unavailable" role="alert" data-testid="offers-unavailable">
          {localizeAdminMessage(snapshot.message) ?? "مصدر العروض غير متاح."}
        </p>
      ) : snapshot.state === "empty" ? (
        <p data-testid="offers-empty">
          {snapshot.message ?? "لا توجد عروض للعرض حاليًا."}
        </p>
      ) : (
        <DataTable
          density="comfortable"
          emptyState={{
            title: "لا توجد عروض مطابقة",
            description: "جرّب تعديل البحث أو مسح فلتر الحالة.",
            action: hasActiveFilter ? { label: "مسح الفلاتر", onClick: resetFilters } : undefined,
          }}
          rows={filteredItems}
          stickyHeader
          testId="offers-table"
        >
            <thead>
              <tr>
                <th>العنوان</th>
                <th>الجهة</th>
                <th>حالة العرض</th>
                <th>نشط</th>
                <th>مميز</th>
                <th>تاريخ الإنشاء</th>
                {canModerate ? <th>الخيارات</th> : null}
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.id} data-testid={`offer-row-${item.id}`}>
                  <td>
                    <div className="media-center-cell">
                      <strong>{item.title}</strong>
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
                    {item.isFeatured ? (
                      <StatusBadge tone="success" title="يتم التحكم به عبر الخدمة الآمنة">
                        مميز
                        {item.featuredUntil
                          ? ` حتى ${formatAdminDate(item.featuredUntil, { dateOnly: true })}`
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
                        targetType="offer"
                        canModerate={canModerate}
                        mode="dropdown"
                      />
                    </td>
                  ) : null}
                </tr>
              ))}
            </tbody>
          </DataTable>
      )}

      <div className="media-center-non-goals" data-testid="offers-non-goals">
        <p className="muted-text">
          إذا تعذر الاتصال بالخدمة أو كانت البيانات قديمة، تظهر الصفحة ذلك
          بوضوح بدل إظهار نجاح غير حقيقي.
        </p>
      </div>
    </section>
  );
}

function getStateFilterLabel(value: ContentAdminState | "all") {
  return STATE_FILTER_OPTIONS.find((option) => option.value === value)?.label ?? value;
}
