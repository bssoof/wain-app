"use client";

import { useEffect, useMemo, useState } from "react";

import {
  formatAdminDate,
  localizeAdminFreshnessNote,
  localizeAdminLabel,
  localizeAdminMessage,
} from "@/lib/admin/admin-localization";
import { compareAdminText } from "@/lib/admin/stable-text-sort";
import {
  buildMediaCommandRequest,
  buildMediaItemActionAffordances,
  commandKey,
  getMediaActionStateClass,
  type MediaCenterBaseline,
  type MediaCenterItem,
  type MediaCenterSection,
  type MediaCommandType,
  type MediaReferenceSafety,
  type MediaSectionKey,
} from "@/lib/media";

import { useOptionalMediaCommands } from "./media-command-provider";
import {
  type ActiveFilterChip,
  FilterField,
  FilterSelect,
  FilterTextInput,
  FilterToolbar,
} from "../shared/filter-toolbar";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";
import { EmptyState } from "../shared/ui/empty-state";

export function MediaCenterShell({
  baseline,
}: {
  baseline: MediaCenterBaseline;
}) {
  const mediaCommands = useOptionalMediaCommands();
  const [activeSectionKey, setActiveSectionKey] = useState<MediaSectionKey>(
    baseline.sections[0]?.key ?? "proofs",
  );
  const [searchTerm, setSearchTerm] = useState("");
  const [venueFilter, setVenueFilter] = useState("");
  const [safetyFilter, setSafetyFilter] = useState<"" | MediaReferenceSafety>("");
  const [previewItem, setPreviewItem] = useState<MediaCenterItem | null>(null);
  const [selectedActionItemId, setSelectedActionItemId] = useState<string | null>(null);

  const activeSection =
    baseline.sections.find((section) => section.key === activeSectionKey) ??
    baseline.sections[0];

  useEffect(() => {
    setPreviewItem(null);
    setSelectedActionItemId(null);
  }, [activeSection?.key]);

  if (!activeSection) {
    return (
      <section
        className="card media-center-shell"
        data-testid="media-center-shell"
        dir="rtl"
        lang="ar"
      >
        <p data-testid="media-center-empty-shell">
          لا توجد صور أو ملفات للعرض حاليًا.
        </p>
      </section>
    );
  }

  const venueOptions = useMemo(
    () =>
      Array.from(
        new Set(
          activeSection.items
            .map((item) => item.venueName?.trim())
            .filter((value): value is string => Boolean(value)),
        ),
      ).sort(compareAdminText),
    [activeSection.items],
  );

  const filteredItems = useMemo(
    () =>
      filterMediaItems(activeSection.items, {
        searchTerm,
        venueName: venueFilter,
        referenceSafety: safetyFilter || undefined,
      }),
    [activeSection.items, searchTerm, venueFilter, safetyFilter],
  );

  const hasActiveFilter =
    searchTerm.trim().length > 0 || venueFilter.length > 0 || safetyFilter.length > 0;
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
        venueFilter
          ? {
              key: "venue",
              label: "الجهة",
              value: venueFilter,
              onRemove: () => setVenueFilter(""),
            }
          : null,
        safetyFilter
          ? {
              key: "safety",
              label: "حالة الارتباط",
              value: formatSafety(safetyFilter),
              onRemove: () => setSafetyFilter(""),
            }
          : null,
      ].filter((filter): filter is ActiveFilterChip => filter !== null),
    [safetyFilter, searchTerm, venueFilter],
  );

  function resetFilters() {
    setSearchTerm("");
    setVenueFilter("");
    setSafetyFilter("");
  }

  useEffect(() => {
    if (filteredItems.length === 0) {
      setSelectedActionItemId(null);
      return;
    }

    if (
      !selectedActionItemId ||
      !filteredItems.some((item) => item.id === selectedActionItemId)
    ) {
      setSelectedActionItemId(filteredItems[0]?.id ?? null);
    }
  }, [filteredItems, selectedActionItemId]);

  const selectedActionItem =
    filteredItems.find((item) => item.id === selectedActionItemId) ??
    filteredItems[0] ??
    null;

  const localizedSource = localizeAdminLabel(activeSection.source);

  return (
    <section
      className="card media-center-shell"
      data-testid="media-center-shell"
      dir="rtl"
      lang="ar"
    >
      <p className="muted-text" data-testid="media-center-read-only-note">
        تعرض هذه الصفحة صور وملفات الجهات، وتوضح ما يمكن مراجعته أو تعديله حسب
        صلاحيتك. كل تعديل يمر عبر الخادم، وأدوار القراءة ترى البيانات فقط.
      </p>

      <div className="media-center-summary-grid" data-testid="media-center-summary-grid">
        <div className="media-center-summary-item">
          <span className="muted-text">وقت الإنشاء</span>
          <strong>{formatAdminDate(baseline.generatedAt)}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">الأقسام</span>
          <strong>{baseline.sections.length}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">مصدر البيانات</span>
          <strong>{localizedSource}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">طريقة الاستخدام</span>
          <strong>{mediaCommands ? "تعديل حسب الصلاحية" : "عرض فقط"}</strong>
        </div>
      </div>

      <div className="media-center-tabs" role="tablist" aria-label="أقسام الصور والملفات">
        {baseline.sections.map((section) => {
          const active = section.key === activeSection.key;
          return (
            <button
              key={section.key}
              type="button"
              role="tab"
              aria-selected={active ? "true" : "false"}
              className={active ? "media-center-tab active" : "media-center-tab"}
              onClick={() => setActiveSectionKey(section.key)}
              data-testid={`media-center-tab-${section.key}`}
            >
              <span>{section.title}</span>
              <small>{localizeAdminLabel(section.state)}</small>
            </button>
          );
        })}
      </div>

      <div
        className="media-center-section-header"
        data-testid={`media-center-section-${activeSection.key}`}
      >
        <div>
          <h2>{activeSection.title}</h2>
          <p className="status-note">{activeSection.scopeNote}</p>
        </div>
        <StatusBadge
          className={mediaStateClass(activeSection)}
          testId="media-center-state-badge"
        >
          {formatState(activeSection.state)}
        </StatusBadge>
      </div>

      <div className="media-center-state-note" data-testid="media-center-source-note">
        <p className="muted-text">مصدر البيانات: {localizedSource}</p>
        <p className="muted-text">حالة البيانات: {localizeAdminFreshnessNote(activeSection.freshnessNote)}</p>
        <p className="muted-text">
          حالة الارتباط:{" "}
          {localizeAdminMessage(activeSection.referenceSafetyNote) ??
            activeSection.referenceSafetyNote}
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
            placeholder="ابحث باسم الملف أو الجهة أو رقم الارتباط"
            data-testid="media-center-search-input"
          />
        </FilterField>

        <FilterField label="الجهة" className="media-center-filter-field">
          <FilterSelect
            className="media-center-filter-select"
            value={venueFilter}
            onChange={(event) => setVenueFilter(event.target.value)}
            data-testid="media-center-venue-filter"
          >
            <option value="">كل الجهات</option>
            {venueOptions.map((venueName) => (
              <option key={venueName} value={venueName}>
                {venueName}
              </option>
            ))}
          </FilterSelect>
        </FilterField>

        <FilterField label="حالة الارتباط" className="media-center-filter-field">
          <FilterSelect
            className="media-center-filter-select"
            value={safetyFilter}
            onChange={(event) =>
              setSafetyFilter(event.target.value as "" | MediaReferenceSafety)
            }
            data-testid="media-center-safety-filter"
          >
            <option value="">كل حالات الارتباط</option>
            <option value="safe">آمن</option>
            <option value="unknown">غير محسوم</option>
            <option value="unsafe">غير آمن</option>
          </FilterSelect>
        </FilterField>
      </FilterToolbar>

      {activeSection.state === "unavailable" ? (
        <p
          className="finance-read-inline-unavailable"
          role="alert"
          data-testid="media-center-unavailable"
        >
          {localizeAdminMessage(activeSection.message) ?? activeSection.message}
        </p>
      ) : activeSection.state === "empty" ? (
        <div data-testid="media-center-empty">
          <EmptyState
            compact
            title="لا توجد ملفات في هذا القسم"
            description={localizeAdminMessage(activeSection.message) ?? activeSection.message}
          />
        </div>
      ) : (
        <div className={mediaCommands ? "media-center-workspace" : undefined}>
          <DataTable
            density="comfortable"
            emptyState={{
              title: "لا توجد ملفات مطابقة",
              description: "جرّب تعديل البحث أو إزالة فلاتر الارتباط.",
              action: hasActiveFilter ? { label: "مسح الفلاتر", onClick: resetFilters } : undefined,
            }}
            rows={filteredItems}
            stickyHeader
            testId="media-center-table"
          >
            <thead>
              <tr>
                <th>الملف</th>
                <th>المعاينة</th>
                <th>الجهة</th>
                <th>الارتباط</th>
                <th>مكان الحفظ</th>
                <th>الحالة</th>
                <th>تاريخ الرفع</th>
                {mediaCommands ? <th>اللوحة الجانبية</th> : null}
              </tr>
            </thead>
            <tbody>
              {filteredItems.map((item) => (
                <tr key={item.id} data-testid={`media-center-row-${item.id}`}>
                  <td>
                    <div className="media-center-cell">
                      <strong>{item.title}</strong>
                      <span className="muted-text">{item.previewNote}</span>
                    </div>
                  </td>
                  <td>
                    <div className="media-preview-cell">
                      <button
                        type="button"
                        className="action-button action-button-secondary media-preview-button"
                        onClick={() => setPreviewItem(item)}
                        data-testid={`media-preview-open-${item.id}`}
                      >
                        معاينة
                      </button>
                      <span className="muted-text">
                        {resolvePreviewSource(item.mediaUrl)
                          ? "يمكن فتح المعاينة مباشرة."
                          : "لا توجد معاينة مباشرة لهذا الملف."}
                      </span>
                    </div>
                  </td>
                  <td>{item.venueName ?? "غير متاح"}</td>
                  <td>
                    <div className="media-center-cell">
                      <span>{formatMediaReferenceType(item.referenceType)}</span>
                      <span className="muted-text">{item.referenceId}</span>
                    </div>
                  </td>
                  <td>
                    <div className="media-center-cell">
                      <span>{formatMediaSource(item.sourceLabel)}</span>
                      <span className="muted-text">{formatMediaSourceDocument(item.sourceDocument)}</span>
                    </div>
                  </td>
                  <td>
                    <StatusBadge className={referenceSafetyClass(item.referenceSafety)}>
                      {formatSafety(item.referenceSafety)}
                    </StatusBadge>
                  </td>
                  <td>{formatAdminDate(item.uploadedAt)}</td>
                  {mediaCommands ? (
                    <td>
                      <button
                        type="button"
                        className="action-button action-button-secondary"
                        onClick={() => setSelectedActionItemId(item.id)}
                        data-testid={`media-sidebar-open-${item.id}`}
                      >
                        {selectedActionItem?.id === item.id ? "محدد" : "فتح الخيارات"}
                      </button>
                    </td>
                  ) : null}
                </tr>
              ))}
            </tbody>
          </DataTable>

          {mediaCommands ? (
            <MediaActionSidebar item={selectedActionItem} section={activeSection} />
          ) : null}
        </div>
      )}

      {previewItem ? (
        <MediaPreviewDialog
          item={previewItem}
          sectionTitle={activeSection.title}
          onClose={() => setPreviewItem(null)}
        />
      ) : null}

      <div className="media-center-non-goals" data-testid="media-center-non-goals">
        <p className="muted-text">
          كل التعديلات تمر عبر الخادم. وإذا تعذر الاتصال بالخدمة، تعرض الصفحة
          حالة واضحة بدل إظهار نجاح غير حقيقي.
        </p>
      </div>
    </section>
  );
}

function MediaActionSidebar({
  item,
  section,
}: {
  item: MediaCenterItem | null;
  section: MediaCenterSection;
}) {
  const mediaCommands = useOptionalMediaCommands();
  const [selectedCommand, setSelectedCommand] = useState<MediaCommandType | "">("");
  const [replaceDialogOpen, setReplaceDialogOpen] = useState(false);

  useEffect(() => {
    setReplaceDialogOpen(false);
  }, [item?.id]);

  if (!mediaCommands || !item) {
    return (
      <aside className="media-action-sidebar card" data-testid="media-center-sidebar-empty">
        <p className="muted-text">اختر ملفًا من الجدول لعرض خياراته.</p>
      </aside>
    );
  }

  const affordances = buildMediaItemActionAffordances(
    mediaCommands.session,
    item,
    section,
    {
      media_reference_check: mediaCommands.getRuntimeState(
        commandKey("media_reference_check", item.id),
      ),
      media_soft_delete: mediaCommands.getRuntimeState(
        commandKey("media_soft_delete", item.id),
      ),
      media_quarantine: mediaCommands.getRuntimeState(
        commandKey("media_quarantine", item.id),
      ),
      media_purge: mediaCommands.getRuntimeState(commandKey("media_purge", item.id)),
    },
  );

  const visibleAffordances = Object.values(affordances).filter((affordance) => affordance.visible);

  if (visibleAffordances.length === 0) {
    return (
      <aside
        className="media-action-sidebar card"
        data-testid={`media-center-actions-${item.id}`}
      >
        <div className="media-action-sidebar__header">
          <strong>لوحة الخيارات</strong>
          <span className="muted-text">{item.title}</span>
        </div>
        <p className="muted-text" data-testid={`media-center-read-only-${item.id}`}>
          هذا الدور يملك صلاحية القراءة فقط.
        </p>
      </aside>
    );
  }

  const selectedAffordance =
    visibleAffordances.find((affordance) => affordance.command === selectedCommand) ??
    visibleAffordances[0];

  const executeCommand = async (command: MediaCommandType) => {
    const runtimeKey = commandKey(command, item.id);
    await mediaCommands.runCommand(
      runtimeKey,
      command,
      buildMediaCommandRequest(command, item, section),
    );
  };

  const selectedRuntimeKey = commandKey(selectedAffordance.command, item.id);
  const selectedRuntimeMessage =
    mediaCommands.getLastMessage(selectedRuntimeKey) ?? selectedAffordance.message;

  return (
    <aside className="media-action-sidebar card" data-testid={`media-center-actions-${item.id}`}>
      <div className="media-action-sidebar__header">
        <strong>لوحة الخيارات</strong>
        <span className="muted-text">{item.title}</span>
      </div>

      <label className="action-dropdown__field">
        <span className="muted-text">اختر الإجراء</span>
        <select
          className="action-dropdown__select"
          value={selectedAffordance.command}
          onChange={(event) => setSelectedCommand(event.target.value as MediaCommandType)}
          data-testid={`media-action-select-${item.id}`}
        >
          {visibleAffordances.map((affordance) => (
            <option key={affordance.command} value={affordance.command}>
              {affordance.label}
            </option>
          ))}
        </select>
      </label>

      <div className="action-dropdown__footer">
        <button
          type="button"
          className="action-button action-button-secondary"
          disabled={!selectedAffordance.enabled}
          aria-busy={selectedAffordance.runtimeState === "pending" ? "true" : "false"}
          onClick={() => void executeCommand(selectedAffordance.command)}
          data-testid={`media-action-run-${item.id}`}
        >
          {selectedAffordance.label}
        </button>
        <StatusBadge className={getMediaActionStateClass(selectedAffordance.runtimeState)}>
          {selectedAffordance.statusText}
        </StatusBadge>
      </div>

      <div data-testid={`media-command-${selectedAffordance.command}-${item.id}`}>
        <MediaActionStateMessage
          runtimeState={selectedAffordance.runtimeState}
          message={selectedRuntimeMessage}
        />
        <span className="muted-text">
          الصلاحية: {localizeAdminLabel(selectedAffordance.requiredCapability)}
        </span>
      </div>

      <div className="media-replace-launcher" data-testid={`media-replace-launcher-${item.id}`}>
        <button
          type="button"
          className="action-button action-button-secondary"
          onClick={() => setReplaceDialogOpen(true)}
          data-testid={`media-replace-open-${item.id}`}
        >
          استبدال الملف
        </button>
        <span className="muted-text">
          يجهز طلب استبدال للمراجعة ولا يغير الملف الآن.
        </span>
      </div>

      {replaceDialogOpen ? (
        <MediaReplaceDialog
          item={item}
          section={section}
          onClose={() => setReplaceDialogOpen(false)}
        />
      ) : null}
    </aside>
  );
}

function MediaActionStateMessage({
  runtimeState,
  message,
}: {
  runtimeState: ReturnType<typeof buildMediaItemActionAffordances>["referenceCheck"]["runtimeState"];
  message?: string;
}) {
  if (!message) {
    return null;
  }

  if (runtimeState === "blocked") {
    return (
      <p className="muted-text media-action-message" data-testid="media-command-blocked-message">
        {message}
      </p>
    );
  }

  if (runtimeState === "success") {
    return (
      <p className="muted-text media-action-message" data-testid="media-command-success-message">
        {message}
      </p>
    );
  }

  if (runtimeState === "conflict" || runtimeState === "unavailable") {
    return (
      <p
        className="finance-read-inline-unavailable media-action-message"
        role="alert"
        data-testid={`media-command-${runtimeState}-message`}
      >
        {message}
      </p>
    );
  }

  return null;
}

function MediaPreviewDialog({
  item,
  sectionTitle,
  onClose,
}: {
  item: MediaCenterItem;
  sectionTitle: string;
  onClose: () => void;
}) {
  const previewSource = resolvePreviewSource(item.mediaUrl);

  useEffect(() => {
    const handleKeydown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keydown", handleKeydown);
    return () => {
      window.removeEventListener("keydown", handleKeydown);
    };
  }, [onClose]);

  return (
    <div
      className="media-preview-dialog-backdrop"
      role="presentation"
      onClick={(event) => {
        if (event.target === event.currentTarget) {
          onClose();
        }
      }}
      data-testid="media-preview-backdrop"
    >
      <div
        className="card media-preview-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="media-preview-dialog-title"
        data-testid="media-preview-dialog"
      >
        <div className="media-preview-dialog__header">
          <div>
            <h2 id="media-preview-dialog-title">معاينة الملف</h2>
            <p className="muted-text">{item.title}</p>
          </div>
          <button
            type="button"
            className="action-button action-button-secondary"
            onClick={onClose}
            data-testid="media-preview-close"
          >
            إغلاق
          </button>
        </div>

        <div className="media-preview-dialog__body">
          {previewSource ? (
            <img
              className="media-preview-dialog__image"
              src={previewSource}
              alt={`معاينة ${item.title}`}
              data-testid="media-preview-image"
            />
          ) : (
            <p
              className="finance-read-inline-unavailable"
              role="alert"
              data-testid="media-preview-unavailable"
            >
              لا توجد معاينة مباشرة يمكن عرضها لهذا الملف.
            </p>
          )}
        </div>

        <div className="media-preview-dialog__meta">
          <p className="muted-text">القسم: {sectionTitle}</p>
          <p className="muted-text">الارتباط: {formatMediaReferenceType(item.referenceType)} / {item.referenceId}</p>
          <p className="muted-text">مكان الحفظ: {formatMediaSourceDocument(item.sourceDocument)}</p>
          {previewSource ? (
            <a
              href={previewSource}
              target="_blank"
              rel="noreferrer"
              className="dashboard-inline-link"
              data-testid="media-preview-open-link"
            >
              فتح رابط المعاينة في تبويب جديد
            </a>
          ) : null}
        </div>
      </div>
    </div>
  );
}

type MediaReplaceCopyState = "idle" | "success" | "manual-copy" | "copy-failed";

function MediaReplaceDialog({
  item,
  section,
  onClose,
}: {
  item: MediaCenterItem;
  section: MediaCenterSection;
  onClose: () => void;
}) {
  const [replacementUrl, setReplacementUrl] = useState(
    resolvePreviewSource(item.mediaUrl) ?? "",
  );
  const [reason, setReason] = useState("");
  const [urlError, setUrlError] = useState<string | null>(null);
  const [reasonError, setReasonError] = useState<string | null>(null);
  const [draftPayload, setDraftPayload] = useState<string | null>(null);
  const [copyState, setCopyState] = useState<MediaReplaceCopyState>("idle");

  useEffect(() => {
    const handleKeydown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        onClose();
      }
    };

    window.addEventListener("keydown", handleKeydown);
    return () => {
      window.removeEventListener("keydown", handleKeydown);
    };
  }, [onClose]);

  const prepareDraft = async () => {
    const normalizedUrl = replacementUrl.trim();
    const normalizedReason = reason.trim();

    const nextUrlError = /^(https?:\/\/|blob:|data:)/i.test(normalizedUrl)
      ? null
      : "أدخل رابطًا مباشرًا صالحًا للملف الجديد.";
    const nextReasonError =
      normalizedReason.length >= 8
        ? null
        : "سبب الاستبدال يجب أن يكون 8 أحرف على الأقل.";

    setUrlError(nextUrlError);
    setReasonError(nextReasonError);

    if (nextUrlError || nextReasonError) {
      setDraftPayload(null);
      setCopyState("idle");
      return;
    }

    const payload = JSON.stringify(
      buildMediaReplaceDraftPayload(item, section, normalizedUrl, normalizedReason),
      null,
      2,
    );
    setDraftPayload(payload);

    if (
      typeof navigator === "undefined" ||
      !navigator.clipboard ||
      typeof navigator.clipboard.writeText !== "function"
    ) {
      setCopyState("manual-copy");
      return;
    }

    try {
      await navigator.clipboard.writeText(payload);
      setCopyState("success");
    } catch {
      setCopyState("copy-failed");
    }
  };

  return (
    <div
      className="media-replace-dialog-backdrop"
      role="presentation"
      onClick={(event) => {
        if (event.target === event.currentTarget) {
          onClose();
        }
      }}
      data-testid="media-replace-backdrop"
    >
      <div
        className="card media-replace-dialog"
        role="dialog"
        aria-modal="true"
        aria-labelledby="media-replace-dialog-title"
        data-testid="media-replace-dialog"
      >
        <div className="media-replace-dialog__header">
          <div>
            <h2 id="media-replace-dialog-title">طلب استبدال ملف</h2>
            <p className="muted-text">{item.title}</p>
          </div>
          <button
            type="button"
            className="action-button action-button-secondary"
            onClick={onClose}
            data-testid="media-replace-close"
          >
            إغلاق
          </button>
        </div>

        <p className="muted-text">
          هذا الطلب للتحضير والمراجعة فقط. لا يتم تغيير أي ملف الآن، ولا ينفذ
          أي تعديل قبل اعتماده من المسار المخصص.
        </p>

        <form
          className="media-replace-form"
          onSubmit={(event) => {
            event.preventDefault();
            void prepareDraft();
          }}
        >
          <label className="media-replace-field">
            <span>رابط الملف البديل</span>
            <input
              type="text"
              className="media-replace-input"
              value={replacementUrl}
              onChange={(event) => setReplacementUrl(event.target.value)}
              placeholder="أدخل رابط الملف الجديد"
              data-testid={`media-replace-url-input-${item.id}`}
            />
          </label>
          {urlError ? (
            <p
              className="finance-read-inline-unavailable media-action-message"
              role="alert"
              data-testid="media-replace-url-error"
            >
              {urlError}
            </p>
          ) : null}

          <label className="media-replace-field">
            <span>سبب الاستبدال</span>
            <textarea
              className="media-replace-textarea"
              rows={3}
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              placeholder="اكتب سبب الاستبدال بشكل واضح."
              data-testid={`media-replace-reason-input-${item.id}`}
            />
          </label>
          {reasonError ? (
            <p
              className="finance-read-inline-unavailable media-action-message"
              role="alert"
              data-testid="media-replace-reason-error"
            >
              {reasonError}
            </p>
          ) : null}

          <div className="media-replace-actions">
            <button
              type="button"
              className="action-button action-button-secondary"
              onClick={onClose}
              data-testid="media-replace-cancel"
            >
              إلغاء
            </button>
            <button
              type="submit"
              className="action-button action-button-primary"
              data-testid="media-replace-submit"
            >
              تجهيز طلب الاستبدال
            </button>
          </div>
        </form>

        {copyState === "success" ? (
          <p className="muted-text media-action-message" data-testid="media-replace-success-message">
            تم تجهيز الطلب ونسخه إلى الحافظة.
          </p>
        ) : null}
        {copyState === "manual-copy" ? (
          <p className="muted-text media-action-message" data-testid="media-replace-manual-copy-message">
            تم تجهيز الطلب. انسخ محتوى الطلب يدويًا من الصندوق التالي.
          </p>
        ) : null}
        {copyState === "copy-failed" ? (
          <p
            className="finance-read-inline-unavailable media-action-message"
            role="alert"
            data-testid="media-replace-copy-failed-message"
          >
            تعذر النسخ التلقائي. انسخ محتوى الطلب يدويًا من الصندوق التالي.
          </p>
        ) : null}

        {draftPayload ? (
          <div className="media-replace-draft" data-testid="media-replace-draft">
            <p className="muted-text">محتوى طلب الاستبدال</p>
            <pre data-testid="media-replace-draft-payload">{draftPayload}</pre>
          </div>
        ) : null}
      </div>
    </div>
  );
}

function filterMediaItems(
  items: MediaCenterItem[],
  filters: {
    searchTerm: string;
    venueName?: string;
    referenceSafety?: MediaReferenceSafety;
  },
): MediaCenterItem[] {
  const normalizedSearch = filters.searchTerm.trim().toLowerCase();

  return items.filter((item) => {
    const matchesSearch =
      normalizedSearch.length === 0 ||
      [
        item.title,
        item.venueName,
        item.referenceType,
        item.referenceId,
        item.sourceDocument,
      ]
        .filter((value): value is string => Boolean(value))
        .some((value) => value.toLowerCase().includes(normalizedSearch));

    const matchesVenue =
      !filters.venueName ||
      (item.venueName ? item.venueName === filters.venueName : false);

    const matchesSafety =
      !filters.referenceSafety || item.referenceSafety === filters.referenceSafety;

    return matchesSearch && matchesVenue && matchesSafety;
  });
}

function formatState(state: MediaCenterSection["state"]): string {
  switch (state) {
    case "success":
      return "ناجح";
    case "empty":
      return "لا توجد بيانات";
    case "stale":
      return "بيانات قديمة";
    case "unavailable":
      return "غير متاح";
    default:
      return state;
  }
}

function formatSafety(safety: MediaReferenceSafety): string {
  switch (safety) {
    case "safe":
      return "آمن";
    case "unsafe":
      return "غير آمن";
    case "unknown":
      return "غير محسوم";
    default:
      return safety;
  }
}

function formatMediaReferenceType(referenceType: string): string {
  switch (referenceType) {
    case "topup_request":
      return "طلب شحن";
    case "venue":
      return "جهة";
    case "offer":
      return "عرض";
    case "story":
      return "قصة";
    default:
      return "ارتباط غير معروف";
  }
}

function formatMediaSource(source: string): string {
  const collection = source.split("/")[0];

  switch (collection) {
    case "merchant_topup_requests":
      return "طلبات الشحن";
    case "venues":
      return "الجهات";
    case "offers":
      return "العروض";
    case "stories":
      return "القصص";
    default:
      return "مصدر غير معروف";
  }
}

function formatMediaSourceDocument(sourceDocument: string): string {
  const [collection, documentId] = sourceDocument.split("/");
  const source = formatMediaSource(collection);

  return documentId ? `${source} - ${documentId}` : source;
}

function mediaStateClass(
  section: MediaCenterSection,
): "status-success" | "status-warning" | "status-danger" | "status-neutral" {
  if (section.state === "success") {
    return "status-success";
  }
  if (section.state === "stale" || section.state === "empty") {
    return "status-warning";
  }
  return "status-danger";
}

function referenceSafetyClass(
  safety: MediaReferenceSafety,
): "status-success" | "status-warning" | "status-danger" {
  if (safety === "safe") {
    return "status-success";
  }
  if (safety === "unknown") {
    return "status-warning";
  }
  return "status-danger";
}

function buildMediaReplaceDraftPayload(
  item: MediaCenterItem,
  section: MediaCenterSection,
  replacementUrl: string,
  reason: string,
) {
  return {
    action: "media_replace_draft",
    note:
      "طلب تحضيري فقط. أرسل هذا المحتوى عبر مسار الاستبدال المعتمد عندما يصبح متاحًا.",
    section: {
      key: section.key,
      title: section.title,
      referenceIndexHealth: section.referenceIndexHealth,
      purgeBlocked: section.purgeBlocked,
    },
    target: {
      assetId: item.id,
      title: item.title,
      sourceDocument: item.sourceDocument,
      referenceType: item.referenceType,
      referenceId: item.referenceId,
      currentMediaUrl: item.mediaUrl ?? null,
    },
    replacement: {
      mediaUrl: replacementUrl,
      reason,
    },
  } as const;
}

function resolvePreviewSource(mediaUrl?: string): string | null {
  const normalized = mediaUrl?.trim();
  if (!normalized) {
    return null;
  }

  return /^(https?:\/\/|blob:|data:)/i.test(normalized)
    ? normalized
    : null;
}
