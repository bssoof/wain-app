"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";

import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import { compareAdminText } from "@/lib/admin/stable-text-sort";
import { canRenderAction } from "@/lib/auth/guard-api";
import { formatStatus, getStatusColorClass } from "@/lib/finance/read-model-formatters";
import { uploadVenueImageBatch } from "@/lib/venues/venue-image-upload";
import {
  buildCreateVenueRequest,
  buildUpdateVenueOperationalStatusRequest,
  buildUpdateVenueProfileRequest,
  buildUpdateVenueSubscriptionStatusRequest,
  buildUpdateVenueVisibilityRequest,
} from "@/lib/venues/build-venue-command-requests";
import type {
  VenueDirectoryItem,
  VenueDirectoryOperationalStatus,
  VenueDirectoryReadData,
  VenueDirectorySubscriptionStatus,
  VenueDirectorySummary,
  VenueDirectoryVisibilityStatus,
} from "@/lib/venues/venue-directory-models";
import type { VenueDirectoryReadResult } from "@/lib/venues/venue-directory-read-types";

import type { VenueActionRuntimeState } from "./venue-command-provider";
import { useOptionalVenueCommands } from "./venue-command-provider";
import { VenueCreateDialog, type VenueCreateFormValue } from "./venue-create-dialog";
import { VenueEditDialog, type VenueEditFormValue } from "./venue-edit-dialog";
import {
  type ActiveFilterChip,
  FilterField,
  FilterSelect,
  FilterTextInput,
  FilterToolbar,
} from "../shared/filter-toolbar";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";

export function VenueDirectoryShell({
  readResult,
}: {
  readResult: VenueDirectoryReadResult<VenueDirectoryReadData>;
}) {
  const commandContext = useOptionalVenueCommands();
  const [items, setItems] = useState<VenueDirectoryItem[]>(
    readResult.kind === "success" ? readResult.data.items : [],
  );
  const [searchTerm, setSearchTerm] = useState("");
  const [cityFilter, setCityFilter] = useState("");
  const [categoryFilter, setCategoryFilter] = useState("");
  const [subscriptionFilter, setSubscriptionFilter] = useState<"" | VenueDirectorySubscriptionStatus>("");
  const [visibilityFilter, setVisibilityFilter] = useState<"" | VenueDirectoryVisibilityStatus>("");
  const [operationalFilter, setOperationalFilter] = useState<"" | VenueDirectoryOperationalStatus>("");
  const [isCreateOpen, setIsCreateOpen] = useState(false);
  const [editingItem, setEditingItem] = useState<VenueDirectoryItem | null>(null);
  const [isCreateFlowPending, setIsCreateFlowPending] = useState(false);
  const [createFlowNotice, setCreateFlowNotice] = useState<string | null>(null);

  useEffect(() => {
    if (readResult.kind === "success") {
      setItems(readResult.data.items);
    }
  }, [readResult]);

  const filters = useMemo(() => buildVenueFilters(items), [items]);
  const summary = useMemo(() => buildVenueSummary(items), [items]);
  const createVenueRuntimeKey = runtimeKey("create_venue", "dialog");
  const filteredItems = useMemo(
    () =>
      filterItems(items, {
        searchTerm,
        city: cityFilter,
        category: categoryFilter,
        subscriptionStatus: subscriptionFilter,
        visibilityStatus: visibilityFilter,
        operationalStatus: operationalFilter,
      }),
    [
      items,
      searchTerm,
      cityFilter,
      categoryFilter,
      subscriptionFilter,
      visibilityFilter,
      operationalFilter,
    ],
  );

  const canCreateVenue = commandContext
    ? canRenderAction(commandContext.session, "create_venue")
    : false;
  const canEditVenue = commandContext
    ? canRenderAction(commandContext.session, "edit_venue_profile")
    : false;
  const canChangeVisibility = commandContext
    ? canRenderAction(commandContext.session, "change_venue_visibility")
    : false;
  const canChangeOperational = commandContext
    ? canRenderAction(commandContext.session, "change_venue_operational_status")
    : false;
  const canChangeSubscription = commandContext
    ? canRenderAction(commandContext.session, "change_venue_subscription_status")
    : false;

  const hasAnyFilter =
    searchTerm.trim().length > 0 ||
    cityFilter.length > 0 ||
    categoryFilter.length > 0 ||
    subscriptionFilter.length > 0 ||
    visibilityFilter.length > 0 ||
    operationalFilter.length > 0;

  const activeFilterCount =
    Number(searchTerm.trim().length > 0) +
    Number(cityFilter.length > 0) +
    Number(categoryFilter.length > 0) +
    Number(subscriptionFilter.length > 0) +
    Number(visibilityFilter.length > 0) +
    Number(operationalFilter.length > 0);

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
        cityFilter
          ? {
              key: "city",
              label: "المدينة",
              value: cityFilter,
              onRemove: () => setCityFilter(""),
            }
          : null,
        categoryFilter
          ? {
              key: "category",
              label: "التصنيف",
              value: categoryFilter,
              onRemove: () => setCategoryFilter(""),
            }
          : null,
        subscriptionFilter
          ? {
              key: "subscription",
              label: "الاشتراك",
              value: formatStatus(subscriptionFilter),
              onRemove: () => setSubscriptionFilter(""),
            }
          : null,
        visibilityFilter
          ? {
              key: "visibility",
              label: "الظهور",
              value: formatStatus(visibilityFilter),
              onRemove: () => setVisibilityFilter(""),
            }
          : null,
        operationalFilter
          ? {
              key: "operational",
              label: "التشغيل",
              value: formatStatus(operationalFilter),
              onRemove: () => setOperationalFilter(""),
            }
          : null,
      ].filter((filter): filter is ActiveFilterChip => filter !== null),
    [
      categoryFilter,
      cityFilter,
      operationalFilter,
      searchTerm,
      subscriptionFilter,
      visibilityFilter,
    ],
  );

  function resetFilters() {
    setSearchTerm("");
    setCityFilter("");
    setCategoryFilter("");
    setSubscriptionFilter("");
    setVisibilityFilter("");
    setOperationalFilter("");
  }

  async function handleCreateVenue(value: VenueCreateFormValue) {
    if (!commandContext) {
      return;
    }

    setCreateFlowNotice(null);
    setIsCreateFlowPending(true);

    const initialPhotos = uniqueInInputOrder(value.photos ?? []);
    const initialMenuImages = uniqueInInputOrder(value.menuImages ?? []);

    try {
      const request = buildCreateVenueRequest({
        nameAr: value.nameAr,
        nameEn: value.nameEn || undefined,
        city: value.city,
        phone: value.phone || undefined,
        categories: value.categories,
        instagram: value.instagram,
        whatsapp: value.whatsapp,
        facebook: value.facebook,
        website: value.website,
        minPrice: value.minPrice,
        maxPrice: value.maxPrice,
        currency: value.currency,
        photos: initialPhotos,
        menuImages: initialMenuImages,
        hours: value.hours,
        is24h: value.is24h,
        tags: value.tags,
        transportEnabled: value.transportEnabled,
        transportPartnerIds: value.transportPartnerIds,
        transportNotesAr: value.transportNotesAr,
        transportNotesEn: value.transportNotesEn,
        lat: value.lat,
        lng: value.lng,
        reason: value.reason,
      });

      const result = await commandContext.runCommand(createVenueRuntimeKey, request);
      if (!result.ok) {
        return;
      }

      const uploadMessages: string[] = [];
      let mergedPhotos = initialPhotos;
      let mergedMenuImages = initialMenuImages;

      const selectedPhotoFiles = value.photoFiles ?? [];
      if (selectedPhotoFiles.length > 0) {
        try {
          const photoUpload = await uploadVenueImageBatch({
            venueId: result.data.venueId,
            kind: "photos",
            files: selectedPhotoFiles,
          });
          mergedPhotos = uniqueInInputOrder([
            ...mergedPhotos,
            ...photoUpload.uploadedUrls,
          ]);
          if (photoUpload.failed.length > 0) {
            uploadMessages.push(
              formatUploadFailureMessage("صور الجهة", photoUpload.failed.length),
            );
          }
        } catch (error) {
          uploadMessages.push(`تعذر رفع صور الجهة: ${toMessage(error)}`);
        }
      }

      const selectedMenuFiles = value.menuImageFiles ?? [];
      if (selectedMenuFiles.length > 0) {
        try {
          const menuUpload = await uploadVenueImageBatch({
            venueId: result.data.venueId,
            kind: "menu_images",
            files: selectedMenuFiles,
          });
          mergedMenuImages = uniqueInInputOrder([
            ...mergedMenuImages,
            ...menuUpload.uploadedUrls,
          ]);
          if (menuUpload.failed.length > 0) {
            uploadMessages.push(
              formatUploadFailureMessage("صور المنيو", menuUpload.failed.length),
            );
          }
        } catch (error) {
          uploadMessages.push(`تعذر رفع صور المنيو: ${toMessage(error)}`);
        }
      }

      const hadSelectedFiles =
        selectedPhotoFiles.length > 0 || selectedMenuFiles.length > 0;
      if (hadSelectedFiles) {
        const mediaUpdates: {
          photos?: string[];
          menuImages?: string[];
        } = {};

        if (mergedPhotos.length > 0) {
          mediaUpdates.photos = mergedPhotos;
        }
        if (mergedMenuImages.length > 0) {
          mediaUpdates.menuImages = mergedMenuImages;
        }

        if (Object.keys(mediaUpdates).length > 0) {
          const profileUpdateRequest = buildUpdateVenueProfileRequest({
            venueId: result.data.venueId,
            updates: mediaUpdates,
            reason: "ربط الصور المرفوعة مباشرة بعد إنشاء الجهة",
            currentOperationalStatus: "active",
          });

          const profileUpdateResult = await commandContext.runCommand(
            runtimeKey(profileUpdateRequest.action, result.data.venueId),
            profileUpdateRequest,
          );

          if (!profileUpdateResult.ok) {
            uploadMessages.push("تم إنشاء الجهة لكن تعذر حفظ روابط الصور داخل ملف الجهة.");
          }
        }
      }

      if (uploadMessages.length > 0) {
        setCreateFlowNotice(uploadMessages.join(" "));
      } else if (hadSelectedFiles) {
        setCreateFlowNotice("تم إنشاء الجهة ورفع الصور المباشرة بنجاح.");
      }

      const createdItem: VenueDirectoryItem = {
        venueId: result.data.venueId,
        venueName: value.nameAr,
        venueNameEn: value.nameEn || null,
        city: value.city,
        lat: value.lat,
        lng: value.lng,
        categories: value.categories,
        phone: value.phone || null,
        readinessStatus: "unknown",
        readinessSummary: "الجهة جديدة وتحتاج تحديث حالة النظام.",
        walletStatus: "unknown",
        walletSummary: "لا توجد لقطة محفظة بعد.",
        walletBalance: null,
        walletCurrency: "ILS",
        merchantLinkStatus: "unknown",
        merchantLinkSummary: "لا يوجد ربط تاجر بعد.",
        merchantLinkedCount: 0,
        subscriptionStatus: "active",
        visibilityStatus: "visible",
        operationalStatus: "active",
        workspacePath: `/admin/venues/${result.data.venueId}`,
      };

      setItems((current) => sortVenueItems([createdItem, ...current]));
      setIsCreateOpen(false);
    } finally {
      setIsCreateFlowPending(false);
    }
  }

  async function handleEditVenue(value: VenueEditFormValue) {
    if (!commandContext || !editingItem) {
      return;
    }

    const updates = diffVenueProfile(editingItem, value);
    if (Object.keys(updates).length === 0) {
      setEditingItem(null);
      return;
    }

    const request = buildUpdateVenueProfileRequest({
      venueId: editingItem.venueId,
      updates,
      reason: value.reason,
      currentOperationalStatus: "active",
    });

    const result = await commandContext.runCommand(runtimeKey(request.action, editingItem.venueId), request);
    if (!result.ok) {
      return;
    }

    setItems((current) =>
      sortVenueItems(
        current.map((item) =>
          item.venueId === editingItem.venueId
            ? {
                ...item,
                venueName: value.nameAr,
                venueNameEn: value.nameEn || null,
                city: value.city,
                lat: value.lat ?? item.lat ?? null,
                lng: value.lng ?? item.lng ?? null,
                phone: value.phone || null,
                categories: value.categories,
              }
            : item,
        ),
      ),
    );
    setEditingItem(null);
  }

  async function handleVisibilityChange(item: VenueDirectoryItem, nextVisibility: VenueDirectoryVisibilityStatus) {
    if (!commandContext) {
      return;
    }

    const request = buildUpdateVenueVisibilityRequest({
      venueId: item.venueId,
      newVisibility: nextVisibility,
      currentVisibility: item.visibilityStatus,
      currentOperationalStatus: item.operationalStatus,
      reason: nextVisibility === "hidden" ? "إخفاء الجهة من لوحة الإدارة" : "إظهار الجهة من لوحة الإدارة",
    });

    const result = await commandContext.runCommand(runtimeKey(request.action, item.venueId), request);
    if (!result.ok) {
      return;
    }

    setItems((current) =>
      sortVenueItems(
        current.map((entry) =>
          entry.venueId === item.venueId
            ? { ...entry, visibilityStatus: nextVisibility }
            : entry,
        ),
      ),
    );
  }

  async function handleOperationalStatusChange(
    item: VenueDirectoryItem,
    nextStatus: VenueDirectoryOperationalStatus,
  ) {
    if (!commandContext) {
      return;
    }

    const request = buildUpdateVenueOperationalStatusRequest({
      venueId: item.venueId,
      newStatus: nextStatus,
      currentStatus: item.operationalStatus,
      reason: `تحديث الحالة التشغيلية إلى ${formatStatus(nextStatus)}`,
    });

    const result = await commandContext.runCommand(runtimeKey(request.action, item.venueId), request);
    if (!result.ok) {
      return;
    }

    setItems((current) =>
      sortVenueItems(
        current.map((entry) =>
          entry.venueId === item.venueId
            ? {
                ...entry,
                operationalStatus: nextStatus,
                visibilityStatus: nextStatus === "active" ? entry.visibilityStatus : "hidden",
              }
            : entry,
        ),
      ),
    );
  }

  async function handleSubscriptionStatusChange(
    item: VenueDirectoryItem,
    nextStatus: VenueDirectorySubscriptionStatus,
  ) {
    if (!commandContext) {
      return;
    }

    const request = buildUpdateVenueSubscriptionStatusRequest({
      venueId: item.venueId,
      newStatus: nextStatus,
      currentStatus: item.subscriptionStatus,
      reason: `تحديث حالة الاشتراك إلى ${formatStatus(nextStatus)}`,
    });

    const result = await commandContext.runCommand(runtimeKey(request.action, item.venueId), request);
    if (!result.ok) {
      return;
    }

    setItems((current) =>
      sortVenueItems(
        current.map((entry) =>
          entry.venueId === item.venueId
            ? { ...entry, subscriptionStatus: nextStatus }
            : entry,
        ),
      ),
    );
  }

  if (readResult.kind === "unavailable") {
    return (
      <section className="card venue-directory-shell" data-testid="venue-directory-shell">
        <p data-testid="venue-directory-unavailable">
          المصدر غير متاح: {localizeAdminMessage(readResult.message) ?? readResult.message}
        </p>
      </section>
    );
  }

  return (
    <section className="venue-directory-shell" data-testid="venue-directory-shell">
      <div className="card venue-directory-toolbar">
        <div>
          <h2>قائمة الجهات</h2>
          <p className="muted-text">
            {commandContext
              ? "تابع الجهات وعدّل بياناتها حسب صلاحيتك."
              : "هذه الجلسة للعرض فقط. لا تظهر خيارات التعديل."}
          </p>
          <div className="venue-directory-toolbar__meta">
            <span className="muted-text" data-testid="venue-directory-result-count">
              يعرض {filteredItems.length} من أصل {items.length} جهة
            </span>
            {hasAnyFilter ? (
              <button
                type="button"
                className="action-button action-button-secondary"
                data-testid="venue-directory-clear-filters"
                onClick={resetFilters}
              >
                مسح الفلاتر ({activeFilterCount})
              </button>
            ) : null}
          </div>
        </div>
        <div className="venue-directory-toolbar__actions">
          {canCreateVenue ? (
            <button type="button" className="action-button" onClick={() => setIsCreateOpen(true)}>
              إضافة جهة
            </button>
          ) : !canEditVenue && !canChangeVisibility && !canChangeOperational && !canChangeSubscription ? (
            <p className="muted-text" data-testid="venue-directory-read-only-note">
              للعرض فقط
            </p>
          ) : null}
        </div>
      </div>

      {createFlowNotice ? (
        <p className="muted-text" data-testid="venue-directory-create-notice">
          {createFlowNotice}
        </p>
      ) : null}

      <div className="venue-directory-summary-grid">
        <SummaryCard label="إجمالي الجهات" value={summary.totalVenues} />
        <SummaryCard label="جاهزة" value={summary.readiness.ready} />
        <SummaryCard label="مخفية" value={summary.visibility.hidden} />
        <SummaryCard label="معلّقة" value={summary.operational.suspended} />
        <SummaryCard label="اشتراك منتهي" value={summary.subscriptions.expired} />
        <SummaryCard label="غير مرتبطة" value={summary.merchantLinks.unlinked} />
      </div>

      {readResult.data.readBudget.partialResults ? (
        <div className="venue-directory-budget-note" data-testid="venue-directory-budget-note">
          البيانات الحالية جزئية وقد لا تشمل كل الجهات.
          {readResult.data.readBudget.truncatedBounds.length > 0 ? (
            <p className="finance-read-stale-note" data-testid="venue-directory-budget-truncated">
              مناطق لم تكتمل: {readResult.data.readBudget.truncatedBounds.join(", ")}
            </p>
          ) : null}
        </div>
      ) : null}

      <div className="card">
        <FilterToolbar
          activeFilters={activeFilters}
          className="venue-directory-filter-row"
          onClearAll={hasAnyFilter ? resetFilters : undefined}
        >
          <FilterField label="بحث" className="venue-directory-filter-field">
            <FilterTextInput
              className="venue-directory-filter-input"
              data-testid="venue-directory-search-input"
              value={searchTerm}
              onChange={(event) => setSearchTerm(event.target.value)}
              placeholder="اسم الجهة، المدينة، الهاتف..."
            />
          </FilterField>
          <FilterField label="المدينة" className="venue-directory-filter-field">
            <FilterSelect
              className="venue-directory-filter-select"
              data-testid="venue-directory-city-filter"
              value={cityFilter}
              onChange={(event) => setCityFilter(event.target.value)}
            >
              <option value="">كل المدن</option>
              {filters.cities.map((city) => (
                <option key={city} value={city}>
                  {city}
                </option>
              ))}
            </FilterSelect>
          </FilterField>
          <FilterField label="التصنيف" className="venue-directory-filter-field">
            <FilterSelect
              className="venue-directory-filter-select"
              data-testid="venue-directory-category-filter"
              value={categoryFilter}
              onChange={(event) => setCategoryFilter(event.target.value)}
            >
              <option value="">كل التصنيفات</option>
              {filters.categories.map((category) => (
                <option key={category} value={category}>
                  {category}
                </option>
              ))}
            </FilterSelect>
          </FilterField>
          <FilterField label="الاشتراك" className="venue-directory-filter-field">
            <FilterSelect
              className="venue-directory-filter-select"
              data-testid="venue-directory-subscription-filter"
              value={subscriptionFilter}
              onChange={(event) =>
                setSubscriptionFilter(event.target.value as "" | VenueDirectorySubscriptionStatus)
              }
            >
              <option value="">كل الحالات</option>
              <option value="active">{formatStatus("active")}</option>
              <option value="paused">{formatStatus("paused")}</option>
              <option value="expired">{formatStatus("expired")}</option>
            </FilterSelect>
          </FilterField>
          <FilterField label="الظهور" className="venue-directory-filter-field">
            <FilterSelect
              className="venue-directory-filter-select"
              data-testid="venue-directory-visibility-filter"
              value={visibilityFilter}
              onChange={(event) =>
                setVisibilityFilter(event.target.value as "" | VenueDirectoryVisibilityStatus)
              }
            >
              <option value="">كل الحالات</option>
              <option value="visible">{formatStatus("visible")}</option>
              <option value="hidden">{formatStatus("hidden")}</option>
            </FilterSelect>
          </FilterField>
          <FilterField label="التشغيل" className="venue-directory-filter-field">
            <FilterSelect
              className="venue-directory-filter-select"
              data-testid="venue-directory-operational-filter"
              value={operationalFilter}
              onChange={(event) =>
                setOperationalFilter(event.target.value as "" | VenueDirectoryOperationalStatus)
              }
            >
              <option value="">كل الحالات</option>
              <option value="active">{formatStatus("active")}</option>
              <option value="suspended">{formatStatus("suspended")}</option>
              <option value="archived">{formatStatus("archived")}</option>
            </FilterSelect>
          </FilterField>
        </FilterToolbar>
      </div>

      <DataTable
        density="comfortable"
        emptyState={{
          title: hasAnyFilter
            ? "لا توجد جهات مطابقة للفلاتر الحالية"
            : "لا توجد جهات في القراءة الحالية",
          description: hasAnyFilter
            ? "جرّب إزالة بعض الفلاتر أو مسحها كلها."
            : "ستظهر الجهات هنا عند توفرها في مصدر القراءة.",
          action: hasAnyFilter
            ? { label: "مسح الفلاتر", onClick: resetFilters }
            : undefined,
        }}
        rows={filteredItems}
        scrollClassName="card venue-directory-table-card"
        stickyHeader
      >
            <thead>
              <tr>
                <th>الجهة</th>
                <th>المدينة</th>
                <th>التصنيفات</th>
                <th>وضع الجهة</th>
                <th>حالة النظام</th>
                <th>المحفظة</th>
                <th>ربط التاجر</th>
                <th>الخيارات</th>
                <th>التفاصيل</th>
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.venueId} data-testid={`venue-directory-row-${item.venueId}`}>
                  <td>
                    <div className="venue-directory-cell">
                      <strong>{item.venueName}</strong>
                      <span className="muted-text">معرّف الجهة: {item.venueId}</span>
                      <span className="muted-text">{item.venueNameEn ?? "لا يوجد اسم بالإنجليزية"}</span>
                      <span className="muted-text">{item.phone ?? "لا يوجد هاتف"}</span>
                    </div>
                  </td>
                  <td>{item.city ?? "غير متاح"}</td>
                  <td>
                    {item.categories.length > 0 ? (
                      <div className="venue-directory-category-list">
                        {item.categories.map((category, index) => (
                          <StatusBadge
                            key={`${item.venueId}-category-${index}`}
                            className="status-neutral"
                          >
                            {category}
                          </StatusBadge>
                        ))}
                      </div>
                    ) : (
                      <span className="muted-text">غير متاح</span>
                    )}
                  </td>
                  <td>
                    <VenueAdminStatusCell item={item} />
                  </td>
                  <td>
                    <StatusLine status={item.readinessStatus} summary={item.readinessSummary} />
                  </td>
                  <td>
                    <StatusLine status={item.walletStatus} summary={item.walletSummary} />
                  </td>
                  <td>
                    <StatusLine status={item.merchantLinkStatus} summary={item.merchantLinkSummary} />
                  </td>
                  <td>
                    <VenueActionCell
                      item={item}
                      canEditVenue={canEditVenue}
                      canChangeVisibility={canChangeVisibility}
                      canChangeOperational={canChangeOperational}
                      canChangeSubscription={canChangeSubscription}
                      onEdit={() => setEditingItem(item)}
                      onVisibilityChange={handleVisibilityChange}
                      onOperationalStatusChange={handleOperationalStatusChange}
                      onSubscriptionStatusChange={handleSubscriptionStatusChange}
                    />
                  </td>
                  <td>
                    <Link className="venue-directory-row-link" href={item.workspacePath}>
                      فتح التفاصيل
                    </Link>
                  </td>
                </tr>
                ))}
            </tbody>
          </DataTable>

      <VenueCreateDialog
        open={isCreateOpen}
        pending={
          isCreateFlowPending ||
          getRuntimeState(commandContext, createVenueRuntimeKey) === "pending"
        }
        onCancel={() => setIsCreateOpen(false)}
        onSubmit={handleCreateVenue}
      />
      <VenueEditDialog
        item={editingItem}
        open={editingItem !== null}
        pending={
          editingItem
            ? getRuntimeState(commandContext, runtimeKey("update_venue_profile", editingItem.venueId)) === "pending"
            : false
        }
        onCancel={() => setEditingItem(null)}
        onSubmit={handleEditVenue}
      />
    </section>
  );
}

function VenueAdminStatusCell({ item }: { item: VenueDirectoryItem }) {
  return (
    <div className="venue-directory-cell">
      <StatusBadge className={getStatusColorClass(item.visibilityStatus)}>
        الظهور: {formatStatus(item.visibilityStatus)}
      </StatusBadge>
      <StatusBadge className={getStatusColorClass(item.operationalStatus)}>
        التشغيل: {formatStatus(item.operationalStatus)}
      </StatusBadge>
      <StatusBadge className={getStatusColorClass(item.subscriptionStatus)}>
        الاشتراك: {formatStatus(item.subscriptionStatus)}
      </StatusBadge>
    </div>
  );
}

function VenueActionCell({
  item,
  canEditVenue,
  canChangeVisibility,
  canChangeOperational,
  canChangeSubscription,
  onEdit,
  onVisibilityChange,
  onOperationalStatusChange,
  onSubscriptionStatusChange,
}: {
  item: VenueDirectoryItem;
  canEditVenue: boolean;
  canChangeVisibility: boolean;
  canChangeOperational: boolean;
  canChangeSubscription: boolean;
  onEdit: () => void;
  onVisibilityChange: (item: VenueDirectoryItem, nextVisibility: VenueDirectoryVisibilityStatus) => void;
  onOperationalStatusChange: (item: VenueDirectoryItem, nextStatus: VenueDirectoryOperationalStatus) => void;
  onSubscriptionStatusChange: (item: VenueDirectoryItem, nextStatus: VenueDirectorySubscriptionStatus) => void;
}) {
  const commandContext = useOptionalVenueCommands();
  const visibilityRuntime = getRuntimeState(commandContext, runtimeKey("update_venue_visibility", item.venueId));
  const operationalRuntime = getRuntimeState(commandContext, runtimeKey("update_venue_operational_status", item.venueId));
  const subscriptionRuntime = getRuntimeState(commandContext, runtimeKey("update_venue_subscription_status", item.venueId));
  const profileRuntime = getRuntimeState(commandContext, runtimeKey("update_venue_profile", item.venueId));
  const [selectedActionKey, setSelectedActionKey] = useState<string>("");

  if (!commandContext || (!canEditVenue && !canChangeVisibility && !canChangeOperational && !canChangeSubscription)) {
    return <span className="muted-text">للعرض فقط</span>;
  }

  const actionOptions: Array<{
    key: string;
    label: string;
    runtime: VenueActionRuntimeState;
    message?: string;
    disabled: boolean;
    execute: () => void;
  }> = [];

  if (canEditVenue) {
    actionOptions.push({
      key: "profile:edit",
      label: "تعديل الملف",
      runtime: profileRuntime,
      message: commandContext.getLastMessage(runtimeKey("update_venue_profile", item.venueId)),
      disabled: profileRuntime === "pending",
      execute: onEdit,
    });
  }

  if (canChangeVisibility) {
    actionOptions.push({
      key: "visibility:toggle",
      label: item.visibilityStatus === "visible" ? "إخفاء" : "إظهار",
      runtime: visibilityRuntime,
      message: commandContext.getLastMessage(runtimeKey("update_venue_visibility", item.venueId)),
      disabled: visibilityRuntime === "pending",
      execute: () =>
        onVisibilityChange(
          item,
          item.visibilityStatus === "visible" ? "hidden" : "visible",
        ),
    });
  }

  if (canChangeOperational) {
    for (const status of nextOperationalStatuses(item.operationalStatus)) {
      actionOptions.push({
        key: `operational:${status}`,
        label: `حالة العمل: ${formatStatus(status)}`,
        runtime: operationalRuntime,
        message: commandContext.getLastMessage(
          runtimeKey("update_venue_operational_status", item.venueId),
        ),
        disabled: operationalRuntime === "pending",
        execute: () => onOperationalStatusChange(item, status),
      });
    }
  }

  if (canChangeSubscription) {
    for (const status of nextSubscriptionStatuses(item.subscriptionStatus)) {
      actionOptions.push({
        key: `subscription:${status}`,
        label: `الاشتراك: ${formatStatus(status)}`,
        runtime: subscriptionRuntime,
        message: commandContext.getLastMessage(
          runtimeKey("update_venue_subscription_status", item.venueId),
        ),
        disabled: subscriptionRuntime === "pending",
        execute: () => onSubscriptionStatusChange(item, status),
      });
    }
  }

  if (actionOptions.length === 0) {
    return <span className="muted-text">للعرض فقط</span>;
  }

  const selectedAction =
    actionOptions.find((option) => option.key === selectedActionKey) ??
    actionOptions[0];

  const selectedRuntime = selectedAction.runtime;
  const selectedMessage = selectedAction.message;

  return (
    <div className="venue-action-dropdown" data-testid={`venue-actions-${item.venueId}`}>
      <label className="venue-action-dropdown__field">
        <span className="muted-text">اختر الإجراء</span>
        <select
          className="venue-action-dropdown__select"
          value={selectedAction.key}
          onChange={(event) => setSelectedActionKey(event.target.value)}
          data-testid={`venue-action-select-${item.venueId}`}
        >
          {actionOptions.map((option) => (
            <option key={option.key} value={option.key}>
              {option.label}
            </option>
          ))}
        </select>
      </label>

      <div className="venue-action-dropdown__footer">
        <button
          type="button"
          className="action-button action-button-secondary"
          disabled={selectedAction.disabled}
          aria-busy={selectedRuntime === "pending" ? "true" : "false"}
          onClick={selectedAction.execute}
          data-testid={`venue-action-run-${item.venueId}`}
        >
          {selectedAction.label}
        </button>
        <StatusBadge className={runtimeClass(selectedRuntime)}>
          {formatStatus(selectedRuntime)}
        </StatusBadge>
      </div>

      {selectedMessage ? (
        <p className="muted-text venue-action-message" data-testid={`venue-action-message-${item.venueId}`}>
          {selectedMessage}
        </p>
      ) : null}
    </div>
  );
}

function SummaryCard({ label, value }: { label: string; value: number }) {
  return (
    <div className="venue-directory-summary-item">
      <span className="muted-text">{label}</span>
      <strong>{value}</strong>
    </div>
  );
}

function StatusLine({ status, summary }: { status: string; summary: string }) {
  return (
    <div className="venue-directory-cell">
      <StatusBadge className={getStatusColorClass(status)}>{formatStatus(status)}</StatusBadge>
      <span className="muted-text">{localizeAdminMessage(summary) ?? summary}</span>
    </div>
  );
}

function runtimeKey(action: string, targetId: string) {
  return `${action}:${targetId}`;
}

function getRuntimeState(
  context: ReturnType<typeof useOptionalVenueCommands>,
  key: string,
): VenueActionRuntimeState {
  return context?.getRuntimeState(key) ?? "idle";
}

function diffVenueProfile(item: VenueDirectoryItem, value: VenueEditFormValue): {
  nameAr?: string;
  nameEn?: string;
  city?: string;
  categories?: string[];
  phone?: string;
  lat?: number;
  lng?: number;
} {
  const updates: {
    nameAr?: string;
    nameEn?: string;
    city?: string;
    categories?: string[];
    phone?: string;
    lat?: number;
    lng?: number;
  } = {};

  if (item.venueName !== value.nameAr) updates.nameAr = value.nameAr;
  if ((item.venueNameEn ?? "") !== value.nameEn) updates.nameEn = value.nameEn;
  if ((item.city ?? "") !== value.city) updates.city = value.city;
  if ((item.phone ?? "") !== value.phone) updates.phone = value.phone;
  if (item.categories.join("|") !== value.categories.join("|")) updates.categories = value.categories;
  const currentLat =
    typeof item.lat === "number" && Number.isFinite(item.lat) ? item.lat : null;
  const currentLng =
    typeof item.lng === "number" && Number.isFinite(item.lng) ? item.lng : null;
  const nextLat =
    typeof value.lat === "number" && Number.isFinite(value.lat) ? value.lat : null;
  const nextLng =
    typeof value.lng === "number" && Number.isFinite(value.lng) ? value.lng : null;

  if (
    nextLat !== null &&
    nextLng !== null &&
    (currentLat !== nextLat || currentLng !== nextLng)
  ) {
    updates.lat = nextLat;
    updates.lng = nextLng;
  }

  return updates;
}

function buildVenueFilters(items: VenueDirectoryItem[]) {
  return {
    cities: uniqueSorted(items.map((item) => item.city).filter(Boolean) as string[]),
    categories: uniqueSorted(items.flatMap((item) => item.categories)),
  };
}

function buildVenueSummary(items: VenueDirectoryItem[]): VenueDirectorySummary {
  const summary: VenueDirectorySummary = {
    totalVenues: items.length,
    readiness: { ready: 0, warning: 0, fail: 0, unknown: 0 },
    wallet: { active: 0, low_balance: 0, inactive: 0, unknown: 0 },
    merchantLinks: { linked: 0, unlinked: 0, unknown: 0 },
    subscriptions: { active: 0, expired: 0, paused: 0 },
    visibility: { visible: 0, hidden: 0 },
    operational: { active: 0, suspended: 0, archived: 0 },
  };

  for (const item of items) {
    summary.readiness[item.readinessStatus] += 1;
    summary.wallet[item.walletStatus] += 1;
    summary.merchantLinks[item.merchantLinkStatus] += 1;
    summary.subscriptions[item.subscriptionStatus] += 1;
    summary.visibility[item.visibilityStatus] += 1;
    summary.operational[item.operationalStatus] += 1;
  }

  return summary;
}

function filterItems(
  items: VenueDirectoryItem[],
  filters: {
    searchTerm: string;
    city: string;
    category: string;
    subscriptionStatus: "" | VenueDirectorySubscriptionStatus;
    visibilityStatus: "" | VenueDirectoryVisibilityStatus;
    operationalStatus: "" | VenueDirectoryOperationalStatus;
  },
) {
  const search = filters.searchTerm.trim().toLowerCase();
  return items.filter((item) => {
    const matchesSearch =
      !search ||
      [
        item.venueId,
        item.venueName,
        item.venueNameEn ?? "",
        item.city ?? "",
        item.phone ?? "",
        item.subscriptionStatus,
        item.visibilityStatus,
        item.operationalStatus,
        ...item.categories,
      ]
        .join(" ")
        .toLowerCase()
        .includes(search);
    const matchesCity = !filters.city || item.city === filters.city;
    const matchesCategory = !filters.category || item.categories.includes(filters.category);
    const matchesSubscription =
      !filters.subscriptionStatus || item.subscriptionStatus === filters.subscriptionStatus;
    const matchesVisibility =
      !filters.visibilityStatus || item.visibilityStatus === filters.visibilityStatus;
    const matchesOperational =
      !filters.operationalStatus || item.operationalStatus === filters.operationalStatus;

    return (
      matchesSearch &&
      matchesCity &&
      matchesCategory &&
      matchesSubscription &&
      matchesVisibility &&
      matchesOperational
    );
  });
}

function nextOperationalStatuses(current: VenueDirectoryOperationalStatus) {
  return (["active", "suspended", "archived"] as const).filter((value) => value !== current);
}

function nextSubscriptionStatuses(current: VenueDirectorySubscriptionStatus) {
  return (["active", "paused", "expired"] as const).filter((value) => value !== current);
}

function uniqueSorted(values: string[]) {
  return [...new Set(values)].sort(compareAdminText);
}

function uniqueInInputOrder(values: string[]) {
  return [...new Set(values.filter((value) => value.trim().length > 0))];
}

function formatUploadFailureMessage(label: string, failedCount: number): string {
  return `${label}: فشل رفع ${failedCount} ملف.`;
}

function toMessage(error: unknown): string {
  if (error instanceof Error && error.message.trim().length > 0) {
    return error.message;
  }

  if (typeof error === "string" && error.trim().length > 0) {
    return error.trim();
  }

  return "خطأ غير متوقع";
}

function sortVenueItems(items: VenueDirectoryItem[]) {
  return [...items].sort((left, right) => compareAdminText(left.venueName, right.venueName));
}

function runtimeClass(runtime: VenueActionRuntimeState) {
  switch (runtime) {
    case "success":
      return "status-success";
    case "pending":
    case "conflict":
      return "status-warning";
    case "blocked":
    case "unavailable":
      return "status-danger";
    default:
      return "status-neutral";
  }
}
