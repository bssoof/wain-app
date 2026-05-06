"use client";

import { useDeferredValue, useMemo, useState } from "react";

import {
  formatAdminDate,
  localizeAdminFreshnessNote,
  localizeAdminLabel,
  localizeAdminMessage,
} from "@/lib/admin/admin-localization";
import { compareAdminText } from "@/lib/admin/stable-text-sort";
import type {
  ReviewModerationSnapshot,
  ReviewModerationStatus,
} from "@/lib/reviews";

import { ReviewActionCell } from "./review-action-cell";
import {
  type ActiveFilterChip,
  FilterField,
  FilterSelect,
  FilterTextInput,
  FilterToolbar,
} from "../shared/filter-toolbar";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";

export function ReviewModerationShell({
  snapshot,
  canModerate,
}: {
  snapshot: ReviewModerationSnapshot;
  canModerate: boolean;
}) {
  const localizedSource = localizeAdminLabel(snapshot.source);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<"" | ReviewModerationStatus>("");
  const [venueFilter, setVenueFilter] = useState("");
  const deferredSearchTerm = useDeferredValue(searchTerm);

  const filteredItems = useMemo(() => {
    const normalizedSearch = deferredSearchTerm.trim().toLowerCase();
    return snapshot.items.filter((item) => {
      const localizedSnippet = localizeReviewSnippet(item.snippet).toLowerCase();
      const localizedAuthorName = localizeReviewAuthorName(item.authorName).toLowerCase();

      if (statusFilter && item.status !== statusFilter) {
        return false;
      }
      if (venueFilter && item.venueName !== venueFilter) {
        return false;
      }
      if (!normalizedSearch) {
        return true;
      }

      return (
        item.snippet.toLowerCase().includes(normalizedSearch) ||
        localizedSnippet.includes(normalizedSearch) ||
        item.id.toLowerCase().includes(normalizedSearch) ||
        item.authorName.toLowerCase().includes(normalizedSearch) ||
        localizedAuthorName.includes(normalizedSearch) ||
        item.venueName.toLowerCase().includes(normalizedSearch)
      );
    });
  }, [snapshot.items, deferredSearchTerm, statusFilter, venueFilter]);

  const venueOptions = useMemo(
    () =>
      Array.from(new Set(snapshot.items.map((item) => item.venueName))).sort(compareAdminText),
    [snapshot.items],
  );

  const hasActiveFilter =
    searchTerm.trim().length > 0 || statusFilter.length > 0 || venueFilter.length > 0;
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
        statusFilter
          ? {
              key: "status",
              label: "الحالة",
              value: localizeAdminLabel(statusFilter),
              onRemove: () => setStatusFilter(""),
            }
          : null,
        venueFilter
          ? {
              key: "venue",
              label: "الجهة",
              value: venueFilter,
              onRemove: () => setVenueFilter(""),
            }
          : null,
      ].filter((filter): filter is ActiveFilterChip => filter !== null),
    [searchTerm, statusFilter, venueFilter],
  );

  function resetFilters() {
    setSearchTerm("");
    setStatusFilter("");
    setVenueFilter("");
  }

  return (
    <section className="card media-center-shell" data-testid="reviews-moderation-shell" dir="rtl" lang="ar">
      <p className="muted-text">
        راجع تعليقات المستخدمين واتخذ قرارًا واضحًا: نشر، إخفاء، أو إرسال للمراجعة.
        أدوار القراءة ترى البيانات فقط ولا تظهر لها خيارات التعديل.
      </p>

      <div className="media-center-summary-grid" data-testid="reviews-summary-grid">
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
          <span className="muted-text">عدد المراجعات</span>
          <strong>{snapshot.items.length}</strong>
        </div>
      </div>

      <div className="media-center-state-note" data-testid="reviews-source-note">
        <p className="muted-text">مصدر البيانات: {localizedSource}</p>
        <p className="muted-text">حالة البيانات: {localizeAdminFreshnessNote(snapshot.freshnessNote)}</p>
        <p className="muted-text">
          الخيارات الحالية: الحالة=
          {snapshot.filtersApplied.statuses.map((entry) => localizeAdminLabel(entry)).join("، ") || "الكل"}؛ الجهة=
          {snapshot.filtersApplied.venueId ?? "الكل"}؛ العدد الأقصى={snapshot.filtersApplied.limit}
        </p>
      </div>

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
            placeholder="ابحث بنص المراجعة أو الكاتب أو الجهة أو رقم المراجعة"
            data-testid="reviews-search-input"
          />
        </FilterField>

        <FilterField label="الحالة" className="media-center-filter-field">
          <FilterSelect
            className="media-center-filter-select"
            value={statusFilter}
            onChange={(event) =>
              setStatusFilter(event.target.value as "" | ReviewModerationStatus)
            }
            data-testid="reviews-status-filter"
          >
            <option value="">كل الحالات</option>
            <option value="published">منشور</option>
            <option value="flagged">تحتاج مراجعة</option>
            <option value="hidden">مخفي</option>
          </FilterSelect>
        </FilterField>

        <FilterField label="الجهة" className="media-center-filter-field">
          <FilterSelect
            className="media-center-filter-select"
            value={venueFilter}
            onChange={(event) => setVenueFilter(event.target.value)}
            data-testid="reviews-venue-filter"
          >
            <option value="">كل الجهات</option>
            {venueOptions.map((venueName) => (
              <option key={venueName} value={venueName}>
                {venueName}
              </option>
            ))}
          </FilterSelect>
        </FilterField>
      </FilterToolbar>

      {snapshot.state === "unavailable" ? (
        <p
          className="finance-read-inline-unavailable"
          role="alert"
          data-testid="reviews-unavailable"
        >
          {localizeAdminMessage(snapshot.message) ?? "مصدر المراجعات غير متاح."}
        </p>
      ) : snapshot.state === "empty" ? (
        <p data-testid="reviews-empty">
          {localizeAdminMessage(snapshot.message) ?? snapshot.message ?? "لا توجد مراجعات للعرض حاليًا."}
        </p>
      ) : (
        <DataTable
          density="comfortable"
          emptyState={{
            title: "لا توجد مراجعات مطابقة",
            description: "جرّب تعديل البحث أو مسح فلاتر الحالة والجهة.",
            action: hasActiveFilter ? { label: "مسح الفلاتر", onClick: resetFilters } : undefined,
          }}
          rows={filteredItems}
          stickyHeader
          testId="reviews-table"
        >
            <thead>
              <tr>
                <th>المراجعة</th>
                <th>الجهة</th>
                <th>التقييم</th>
                <th>حالة المراجعة</th>
                <th>تاريخ الإنشاء</th>
                {canModerate ? <th>الخيارات</th> : null}
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.id} data-testid={`review-row-${item.id}`}>
                  <td>
                    <div className="media-center-cell">
                      <strong>{truncateSnippet(localizeReviewSnippet(item.snippet))}</strong>
                      <span className="muted-text">
                        بواسطة {localizeReviewAuthorName(item.authorName)} - رقم المراجعة: {item.id}
                      </span>
                      {item.moderationReason ? (
                        <span className="muted-text">
                          سبب القرار: {localizeAdminLabel(item.moderationReason)}
                        </span>
                      ) : null}
                    </div>
                  </td>
                  <td>
                    <div className="media-center-cell">
                      <span>{item.venueName}</span>
                      <span className="muted-text">{item.venueId}</span>
                    </div>
                  </td>
                      <td>{item.rating} من 5</td>
                  <td>
                    <StatusBadge className={statusClass(item.status)}>
                      {localizeAdminLabel(item.status)}
                    </StatusBadge>
                  </td>
                  <td>{formatAdminDate(item.createdAt)}</td>
                  {canModerate ? (
                    <td>
                      <ReviewActionCell item={item} canModerate={canModerate} />
                    </td>
                  ) : null}
                </tr>
              ))}
            </tbody>
          </DataTable>
      )}

      <div className="media-center-non-goals" data-testid="reviews-non-goals">
        <p className="muted-text">
          إذا تعذر الاتصال بالخدمة تظهر الصفحة ذلك بوضوح، ولا تعرض نجاحًا وهميًا
          لأي قرار لم يصل إلى الخدمة.
        </p>
      </div>
    </section>
  );
}

function truncateSnippet(value: string): string {
  return value.length > 72 ? `${value.slice(0, 72)}...` : value;
}

function localizeReviewSnippet(value: string): string {
  return localizeAdminMessage(value) ?? value;
}

function localizeReviewAuthorName(value: string): string {
  const trimmed = value.trim();
  if (!trimmed) {
    return "زائر";
  }

  if (/^guest\b/i.test(trimmed)) {
    return trimmed.replace(/^guest\b/i, "زائر");
  }

  return trimmed;
}

function statusClass(value: ReviewModerationStatus): string {
  if (value === "published") {
    return "status-success";
  }
  if (value === "hidden") {
    return "status-danger";
  }
  return "status-warning";
}
