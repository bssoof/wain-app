"use client";

import { useMemo, useState } from "react";

import {
  formatAdminDate,
  localizeAdminFreshnessNote,
  localizeAdminLabel,
  localizeAdminMessage,
} from "@/lib/admin/admin-localization";
import {
  buildConfigCommandRequest,
  commandKey,
  DEFAULT_CONFIG_PRICING,
  getConfigActionStateClass,
  type ConfigCommandRuntimeState,
  type ConfigGovernanceSnapshot,
  type ConfigPricing,
  type ConfigSurfaceAffordances,
} from "@/lib/config";

import { useOptionalConfigCommands } from "./config-command-provider";
import {
  ActionPanel,
  ActionPanelHeader,
  ActionPanelItem,
  ActionPanelMessage,
} from "../shared/action-panel";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";
import { ConfirmDialog } from "../shared/ui/confirm-dialog";
import { EmptyState } from "../shared/ui/empty-state";
import { SkeletonBlock } from "../shared/ui/skeleton-block";

const CONFIG_PRICING_FIELD_LABELS: Record<keyof ConfigPricing, string> = {
  story_promote_1d: "ترويج القصة ليوم واحد",
  story_promote_3d: "ترويج القصة لثلاثة أيام",
  story_promote_7d: "ترويج القصة لسبعة أيام",
  offer_pin_1d: "تثبيت العرض ليوم واحد",
  offer_pin_3d: "تثبيت العرض لثلاثة أيام",
  offer_pin_7d: "تثبيت العرض لسبعة أيام",
  currency: "العملة",
};

const CONFIG_CURRENCY_OPTIONS = [
  { value: "ILS", label: "شيكل" },
  { value: "JOD", label: "دينار" },
  { value: "USD", label: "دولار" },
];

const CONFIG_PRICING_FIELDS: Array<keyof ConfigPricing> = [
  "story_promote_1d",
  "story_promote_3d",
  "story_promote_7d",
  "offer_pin_1d",
  "offer_pin_3d",
  "offer_pin_7d",
  "currency",
];

const CONFIG_SCOPE_LABELS: Record<string, string> = {
  "wallet_feature_pricing/default": "أسعار ميزات المحفظة",
};

type ConfigConfirmAction = "publish" | "rollback";

type ConfigDiffRow = {
  key: string;
  label: string;
  oldValue: string;
  newValue: string;
};

export function ConfigGovernanceShell({
  snapshot,
  affordances,
}: {
  snapshot: ConfigGovernanceSnapshot;
  affordances: ConfigSurfaceAffordances;
}) {
  const localizedSource = localizeAdminLabel(snapshot.source);
  const localizedScope = localizeConfigScope(snapshot.scope);
  const commands = useOptionalConfigCommands();

  const initialPricing =
    snapshot.draft.pricing ?? snapshot.live.pricing ?? DEFAULT_CONFIG_PRICING;

  const [pricingInputs, setPricingInputs] = useState<Record<keyof ConfigPricing, string>>({
    story_promote_1d: String(initialPricing.story_promote_1d),
    story_promote_3d: String(initialPricing.story_promote_3d),
    story_promote_7d: String(initialPricing.story_promote_7d),
    offer_pin_1d: String(initialPricing.offer_pin_1d),
    offer_pin_3d: String(initialPricing.offer_pin_3d),
    offer_pin_7d: String(initialPricing.offer_pin_7d),
    currency: initialPricing.currency,
  });

  const [reason, setReason] = useState("تحديث إعدادات التطبيق");
  const [note, setNote] = useState("");
  const [rollbackToVersion, setRollbackToVersion] = useState(
    snapshot.history[0]?.liveVersion ? String(snapshot.history[0].liveVersion) : "1",
  );

  const [draftStatus, setDraftStatus] = useState(snapshot.draft.status);
  const [draftVersion, setDraftVersion] = useState(snapshot.draft.draftVersion);
  const [liveVersion, setLiveVersion] = useState(snapshot.live.version);
  const [confirmAction, setConfirmAction] = useState<ConfigConfirmAction | null>(null);
  const [confirmLoading, setConfirmLoading] = useState(false);

  const canMutate =
    affordances.canDraft ||
    affordances.canReview ||
    affordances.canPublish ||
    affordances.canRollback;

  const pricing = useMemo(() => {
    const toNumber = (value: string): number => {
      const parsed = Number(value.trim());
      return Number.isFinite(parsed) ? parsed : 0;
    };

    return {
      story_promote_1d: toNumber(pricingInputs.story_promote_1d),
      story_promote_3d: toNumber(pricingInputs.story_promote_3d),
      story_promote_7d: toNumber(pricingInputs.story_promote_7d),
      offer_pin_1d: toNumber(pricingInputs.offer_pin_1d),
      offer_pin_3d: toNumber(pricingInputs.offer_pin_3d),
      offer_pin_7d: toNumber(pricingInputs.offer_pin_7d),
      currency: pricingInputs.currency.trim() || "ILS",
    } as ConfigPricing;
  }, [pricingInputs]);

  const rollbackVersion = useMemo(
    () => parseRollbackVersion(rollbackToVersion),
    [rollbackToVersion],
  );

  const publishDiffRows = useMemo(
    () => buildPricingDiffRows(snapshot.live.pricing ?? DEFAULT_CONFIG_PRICING, pricing),
    [pricing, snapshot.live.pricing],
  );

  const rollbackDiffRows = useMemo(
    () => buildRollbackDiffRows(liveVersion, rollbackVersion, reason),
    [liveVersion, reason, rollbackVersion],
  );

  const upsertRuntimeKey = commandKey("config_upsert_draft");
  const reviewRuntimeKey = commandKey("config_review_draft");
  const publishRuntimeKey = commandKey("publish_config");
  const rollbackRuntimeKey = commandKey("rollback_config");

  const upsertState = commands?.getRuntimeState(upsertRuntimeKey) ?? "idle";
  const reviewState = commands?.getRuntimeState(reviewRuntimeKey) ?? "idle";
  const publishState = commands?.getRuntimeState(publishRuntimeKey) ?? "idle";
  const rollbackState = commands?.getRuntimeState(rollbackRuntimeKey) ?? "idle";

  async function runUpsertDraft() {
    if (!commands || !affordances.canDraft) {
      return;
    }

    const result = await commands.runCommand(
      upsertRuntimeKey,
      "config_upsert_draft",
      buildConfigCommandRequest("config_upsert_draft", {
        pricing,
        draftStatus,
        draftVersion,
        liveVersion,
        reason,
        note: note.trim() || undefined,
      }),
    );

    if (result.ok) {
      setDraftStatus("drafted");
      setDraftVersion(result.data.draftVersion);
    }
  }

  async function runReviewDraft() {
    if (!commands || !affordances.canReview) {
      return;
    }

    const result = await commands.runCommand(
      reviewRuntimeKey,
      "config_review_draft",
      buildConfigCommandRequest("config_review_draft", {
        pricing,
        draftStatus,
        draftVersion,
        liveVersion,
        reason,
        note: note.trim() || undefined,
      }),
    );

    if (result.ok) {
      setDraftStatus("reviewed");
      setDraftVersion(result.data.draftVersion);
    }
  }

  async function runPublishConfig() {
    if (!commands || !affordances.canPublish) {
      return;
    }

    const result = await commands.runCommand(
      publishRuntimeKey,
      "publish_config",
      buildConfigCommandRequest("publish_config", {
        pricing,
        draftStatus,
        draftVersion,
        liveVersion,
        reason,
        note: note.trim() || undefined,
      }),
    );

    if (result.ok) {
      setDraftStatus("published");
      setLiveVersion(result.data.liveVersion);
      setDraftVersion(result.data.draftVersion);
    }
  }

  async function runRollback() {
    if (!commands || !affordances.canRollback) {
      return;
    }

    const result = await commands.runCommand(
      rollbackRuntimeKey,
      "rollback_config",
      buildConfigCommandRequest("rollback_config", {
        pricing,
        draftStatus,
        draftVersion,
        liveVersion,
        rollbackToVersion: rollbackVersion,
        reason,
        note: note.trim() || undefined,
      }),
    );

    if (result.ok) {
      setLiveVersion(result.data.liveVersion);
    }
  }

  async function handleConfirmAction() {
    const action = confirmAction;
    if (!action || confirmLoading) {
      return;
    }

    setConfirmLoading(true);

    try {
      if (action === "publish") {
        await runPublishConfig();
      } else {
        await runRollback();
      }
      setConfirmAction(null);
    } finally {
      setConfirmLoading(false);
    }
  }

  const activeDiffRows = confirmAction === "rollback" ? rollbackDiffRows : publishDiffRows;
  const confirmTitle = confirmAction === "rollback" ? "استرجاع آخر نسخة" : "نشر التغييرات";
  const confirmDescription = confirmAction === "rollback"
    ? "سيتم استرجاع النسخة المحددة بدل النسخة المنشورة الحالية بعد التأكيد."
    : "راجع فروقات الأسعار قبل نشر المسودة كنسخة مباشرة.";
  const confirmLabel = confirmAction === "rollback" ? "تأكيد الاسترجاع" : "تأكيد النشر";
  const confirmEmptyMessage = confirmAction === "rollback"
    ? "لا توجد تفاصيل أسعار تاريخية ضمن اللقطة الحالية؛ تعرض المعاينة رقم النسخة المستهدفة."
    : "لا توجد فروقات أسعار بين المسودة والنسخة المباشرة.";

  return (
    <section className="card media-center-shell" data-testid="config-governance-shell" dir="rtl" lang="ar">
      <header className="config-shell-header">
        <div className="finance-section-heading">
          <h2>إعدادات الأسعار</h2>
          <p className="muted-text">
            عدّل الأسعار، احفظ مسودة، ثم راجعها وانشرها عند الجاهزية.
          </p>
        </div>
        <StatusBadge className="status-neutral">
          {localizeAdminLabel(draftStatus)}
        </StatusBadge>
      </header>

      <div className="media-center-summary-grid" data-testid="config-summary-grid">
        <div className="media-center-summary-item">
          <span className="muted-text">وقت القراءة</span>
          <strong>{formatAdminDate(snapshot.generatedAt)}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">مصدر البيانات</span>
          <strong>{localizedSource}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">النسخة المنشورة</span>
          <strong>{liveVersion}</strong>
        </div>
        <div className="media-center-summary-item">
          <span className="muted-text">حالة المسودة</span>
          <strong>{localizeAdminLabel(draftStatus)}</strong>
        </div>
      </div>

      <div className="media-center-state-note" data-testid="config-source-note">
        <p className="muted-text">مجموعة الإعدادات: {localizedScope}</p>
        <p className="muted-text">حالة البيانات: {localizeAdminFreshnessNote(snapshot.freshnessNote)}</p>
        {snapshot.message ? <p className="muted-text">{localizeAdminMessage(snapshot.message)}</p> : null}
      </div>

      <div className="config-panel" data-testid="config-workflow-guide">
        <div className="config-panel__header">
          <div>
            <h3>خريطة العمل</h3>
            <p className="muted-text">
              نفّذ هذه الخطوات بالترتيب لتفادي تعارض النسخ والحفاظ على مسار نشر واضح.
            </p>
          </div>
        </div>
        <ol className="config-task-list">
          <li className="config-task-item">
            <strong>الخطوة 1: حدّث الأسعار ثم احفظ المسودة</strong>
            <p className="muted-text">
              عدّل القيم المطلوبة أدناه، ثم استخدم إجراء حفظ المسودة لتثبيت النسخة قبل المراجعة.
            </p>
          </li>
          <li className="config-task-item">
            <strong>الخطوة 2: اكتب سبب التغيير ثم نفّذ المراجعة والنشر</strong>
            <p className="muted-text">
              السبب والملاحظة يظهران في السجل، وبعدها نفّذ المراجعة ثم النشر.
            </p>
          </li>
          <li className="config-task-item">
            <strong>الخطوة 3: استخدم الاسترجاع فقط عند الحاجة</strong>
            <p className="muted-text">
              اختر رقم النسخة المراد الرجوع لها ثم نفّذ الاسترجاع مع توثيق سبب واضح.
            </p>
          </li>
        </ol>
      </div>

      <div className="config-panel" data-testid="config-pricing-panel">
        <div className="config-panel__header">
          <div>
            <h3>الخطوة 1: إعداد الأسعار وحفظ المسودة</h3>
            <p className="muted-text">
              أدخل السعر لكل مدة. المبالغ تُحفظ بالعملة المختارة.
            </p>
          </div>
          <span className="muted-text">العملة الحالية: {localizeConfigCurrency(pricing.currency)}</span>
        </div>

        <div className="media-center-filter-row">
          {(
            [
              "story_promote_1d",
              "story_promote_3d",
              "story_promote_7d",
              "offer_pin_1d",
              "offer_pin_3d",
              "offer_pin_7d",
              "currency",
            ] as const
          ).map((field) => (
            <label key={field} className="media-center-filter-field">
              <span className="muted-text">{CONFIG_PRICING_FIELD_LABELS[field]}</span>
              {field === "currency" ? (
                <select
                  className="media-center-filter-select"
                  value={pricingInputs[field]}
                  onChange={(event) =>
                    setPricingInputs((prev) => ({
                      ...prev,
                      [field]: event.target.value,
                    }))
                  }
                  data-testid={`config-pricing-${field}`}
                  disabled={!canMutate}
                >
                  {CONFIG_CURRENCY_OPTIONS.map((option) => (
                    <option key={option.value} value={option.value}>
                      {option.label}
                    </option>
                  ))}
                  {CONFIG_CURRENCY_OPTIONS.some((option) => option.value === pricingInputs[field]) ? null : (
                    <option value={pricingInputs[field]}>
                      {localizeConfigCurrency(pricingInputs[field])}
                    </option>
                  )}
                </select>
              ) : (
                <input
                  className="media-center-filter-input"
                  type="number"
                  min="0"
                  step="1"
                  inputMode="numeric"
                  value={pricingInputs[field]}
                  onChange={(event) =>
                    setPricingInputs((prev) => ({
                      ...prev,
                      [field]: event.target.value,
                    }))
                  }
                  data-testid={`config-pricing-${field}`}
                  disabled={!canMutate}
                />
              )}
            </label>
          ))}
        </div>

        {canMutate && commands ? (
          <ActionPanel className="media-action-stack config-command-grid" testId="config-command-panel-step-1">
            <CommandRow
              testId="config-command-config_upsert_draft"
              label="حفظ المسودة"
              runtimeState={upsertState}
              message={commands.getLastMessage(upsertRuntimeKey)}
              onClick={() => void runUpsertDraft()}
              disabled={!affordances.canDraft || upsertState === "pending"}
            />
          </ActionPanel>
        ) : null}
      </div>

      <div className="config-panel" data-testid="config-change-panel">
        <div className="config-panel__header">
          <div>
            <h3>الخطوة 2: المراجعة والنشر</h3>
            <p className="muted-text">
              السبب يظهر في سجل النشر، والملاحظة تساعد المدقق على فهم القرار.
            </p>
          </div>
        </div>

        <div className="media-center-filter-row">
          <label className="media-center-filter-field">
            <span className="muted-text">سبب التغيير</span>
            <input
              className="media-center-filter-input"
              value={reason}
              onChange={(event) => setReason(event.target.value)}
              data-testid="config-reason-input"
              disabled={!canMutate}
            />
          </label>
          <label className="media-center-filter-field">
            <span className="muted-text">ملاحظة للمراجعة</span>
            <input
              className="media-center-filter-input"
              value={note}
              onChange={(event) => setNote(event.target.value)}
              data-testid="config-note-input"
              disabled={!canMutate}
            />
          </label>
          <label className="media-center-filter-field">
            <span className="muted-text">تنبيه قبل النشر</span>
            <input
              className="media-center-filter-input"
              value="تأكد أن حالة المسودة Reviewed قبل النشر"
              readOnly={true}
              disabled={true}
              aria-label="تنبيه قبل النشر"
            />
          </label>
        </div>

        {canMutate && commands ? (
          <ActionPanel className="media-action-stack config-command-grid" testId="config-command-panel-step-2">
            <CommandRow
              testId="config-command-config_review_draft"
              label="اعتماد المراجعة"
              runtimeState={reviewState}
              message={commands.getLastMessage(reviewRuntimeKey)}
              onClick={() => void runReviewDraft()}
              disabled={!affordances.canReview || reviewState === "pending"}
            />
            <CommandRow
              testId="config-command-publish_config"
              label="نشر"
              runtimeState={publishState}
              message={commands.getLastMessage(publishRuntimeKey)}
              onClick={() => setConfirmAction("publish")}
              disabled={!affordances.canPublish || publishState === "pending"}
            />
          </ActionPanel>
        ) : null}
      </div>

      <div className="config-panel" data-testid="config-rollback-panel">
        <div className="config-panel__header">
          <div>
            <h3>الخطوة 3: الاسترجاع عند الحاجة</h3>
            <p className="muted-text">
              استخدم هذا الإجراء فقط عندما تحتاج الرجوع إلى نسخة منشورة سابقة.
            </p>
          </div>
        </div>

        <div className="media-center-filter-row">
          <label className="media-center-filter-field">
            <span className="muted-text">النسخة المراد الرجوع لها</span>
            <input
              className="media-center-filter-input"
              type="number"
              min="1"
              step="1"
              inputMode="numeric"
              value={rollbackToVersion}
              onChange={(event) => setRollbackToVersion(event.target.value)}
              data-testid="config-rollback-version-input"
              disabled={!canMutate}
            />
          </label>
        </div>

        {canMutate && commands ? (
          <ActionPanel className="media-action-stack config-command-grid" testId="config-command-panel-step-3">
            <CommandRow
              testId="config-command-rollback_config"
              label="استرجاع"
              runtimeState={rollbackState}
              message={commands.getLastMessage(rollbackRuntimeKey)}
              onClick={() => setConfirmAction("rollback")}
              disabled={!affordances.canRollback || rollbackState === "pending"}
            />
          </ActionPanel>
        ) : null}
      </div>

      {snapshot.state === "unavailable" ? (
        <p className="finance-read-inline-unavailable" data-testid="config-unavailable">
          {localizeAdminMessage(snapshot.message) ?? "مصدر إدارة الإعدادات غير متاح."}
        </p>
      ) : null}

      {snapshot.state === "empty" ? (
        <div data-testid="config-empty">
          <EmptyState
            compact
            title="لا توجد إعدادات منشورة بعد"
            description="لم يتم إرجاع أي سجلات لإدارة الإعدادات بعد."
          />
        </div>
      ) : null}

      {!canMutate || !commands ? (
        <p className="muted-text" data-testid="config-read-only-note">
          هذا الدور يستطيع عرض إدارة الإعدادات فقط، ولا يستطيع تنفيذ
          أوامر المسودة أو المراجعة أو النشر أو الاسترجاع.
        </p>
      ) : null}

      <ConfirmDialog
        open={confirmAction !== null}
        onClose={() => {
          if (!confirmLoading) {
            setConfirmAction(null);
          }
        }}
        onConfirm={handleConfirmAction}
        title={confirmTitle}
        description={confirmDescription}
        confirmLabel={confirmLabel}
        cancelLabel="إلغاء"
        variant={confirmAction === "rollback" ? "danger" : "default"}
        loading={confirmLoading}
      >
        <ConfigDiffPreview rows={activeDiffRows} emptyMessage={confirmEmptyMessage} />
      </ConfirmDialog>

      <div className="config-panel">
        <div className="config-panel__header">
          <div>
            <h3>سجل النشر</h3>
            <p className="muted-text">
              آخر النسخ المنشورة أو المسترجعة من الإعدادات.
            </p>
          </div>
        </div>

        <DataTable
          density="compact"
          emptyState={{
            title: "لا يوجد سجل نشر بعد",
            description: "سيظهر سجل النشر والاسترجاع هنا بعد أول عملية ناجحة.",
          }}
          rows={snapshot.history}
          stickyHeader
          testId="config-history-table"
        >
          <thead>
            <tr>
              <th>تاريخ النشر</th>
              <th>النوع</th>
              <th>الإصدار المباشر</th>
              <th>المنفذ</th>
              <th>السبب</th>
            </tr>
          </thead>
          <tbody>
            {snapshot.history.map((item) => (
                <tr key={item.id} data-testid={`config-history-${item.id}`}>
                  <td>{formatAdminDate(item.publishedAt)}</td>
                  <td>{localizeAdminLabel(item.eventType)}</td>
                  <td>{item.liveVersion}</td>
                  <td>{item.publishedByUid ?? "غير معروف"}</td>
                  <td>{item.reason ?? "-"}</td>
                </tr>
              ))}
          </tbody>
        </DataTable>
      </div>

      <div className="media-center-non-goals" data-testid="config-non-goals">
        <p className="muted-text">
          الكتابة من المتصفح لا تكون مباشرة أبدًا. إذا لم يتم ضبط الاتصال بالخدمة
          فستعرض الواجهة حالة عدم التوفر بوضوح بدل إظهار نجاح وهمي.
        </p>
      </div>
    </section>
  );
}

function CommandRow({
  testId,
  label,
  runtimeState,
  message,
  onClick,
  disabled,
}: {
  testId: string;
  label: string;
  runtimeState: ConfigCommandRuntimeState;
  message?: string;
  onClick: () => void;
  disabled: boolean;
}) {
  return (
    <ActionPanelItem className="media-action-item" testId={testId}>
      <ActionPanelHeader className="media-action-item__header">
        <button
          type="button"
          className="action-button action-button-secondary"
          onClick={onClick}
          disabled={disabled}
        >
          {label}
        </button>
        <StatusBadge className={getConfigActionStateClass(runtimeState)}>
          {localizeAdminLabel(runtimeState)}
        </StatusBadge>
      </ActionPanelHeader>
      <CommandRuntimeMessage runtimeState={runtimeState} message={message} />
    </ActionPanelItem>
  );
}

function CommandRuntimeMessage({
  runtimeState,
  message,
}: {
  runtimeState: ConfigCommandRuntimeState;
  message?: string;
}) {
  if (runtimeState === "pending") {
    return (
      <ActionPanelMessage className="media-action-message muted-text" testId="config-command-pending-message">
        <SkeletonBlock height={10} width={120} />
        قيد التنفيذ...
      </ActionPanelMessage>
    );
  }

  if (!message) {
    return null;
  }

  if (runtimeState === "success") {
    return (
      <ActionPanelMessage className="media-action-message muted-text" testId="config-command-success-message">
        {message}
      </ActionPanelMessage>
    );
  }

  if (runtimeState === "conflict") {
    return (
      <ActionPanelMessage className="media-action-message muted-text" testId="config-command-conflict-message">
        {message}
      </ActionPanelMessage>
    );
  }

  if (runtimeState === "blocked") {
    return (
      <ActionPanelMessage className="media-action-message muted-text" testId="config-command-blocked-message">
        {message}
      </ActionPanelMessage>
    );
  }

  return (
    <ActionPanelMessage className="media-action-message muted-text" testId="config-command-unavailable-message">
      {message}
    </ActionPanelMessage>
  );
}

function localizeConfigScope(scope: string): string {
  return CONFIG_SCOPE_LABELS[scope] ?? localizeAdminLabel(scope);
}

function localizeConfigCurrency(currency: string): string {
  const option = CONFIG_CURRENCY_OPTIONS.find(
    (item) => item.value.toLowerCase() === currency.trim().toLowerCase(),
  );

  return option?.label ?? "عملة غير معروفة";
}

function parseRollbackVersion(value: string): number {
  const targetVersion = Number(value.trim());
  return Number.isFinite(targetVersion) && targetVersion > 0
    ? Math.trunc(targetVersion)
    : 1;
}

function buildPricingDiffRows(
  livePricing: ConfigPricing,
  draftPricing: ConfigPricing,
): ConfigDiffRow[] {
  return CONFIG_PRICING_FIELDS.flatMap((field) => {
    const oldValue = livePricing[field];
    const newValue = draftPricing[field];

    if (oldValue === newValue) {
      return [];
    }

    return [
      {
        key: field,
        label: CONFIG_PRICING_FIELD_LABELS[field],
        oldValue: formatConfigDiffValue(field, oldValue),
        newValue: formatConfigDiffValue(field, newValue),
      },
    ];
  });
}

function buildRollbackDiffRows(
  liveVersion: number,
  rollbackVersion: number,
  reason: string,
): ConfigDiffRow[] {
  return [
    {
      key: "rollback-version",
      label: "الإصدار المباشر",
      oldValue: String(liveVersion),
      newValue: String(rollbackVersion),
    },
    {
      key: "rollback-reason",
      label: "سبب الاسترجاع",
      oldValue: "-",
      newValue: reason.trim() || "غير محدد",
    },
  ];
}

function formatConfigDiffValue(
  field: keyof ConfigPricing,
  value: ConfigPricing[keyof ConfigPricing],
): string {
  if (field === "currency") {
    return localizeConfigCurrency(String(value));
  }

  return String(value);
}

function ConfigDiffPreview({
  rows,
  emptyMessage,
}: {
  rows: ConfigDiffRow[];
  emptyMessage: string;
}) {
  return (
    <div className="config-confirm-diff" data-testid="config-confirm-diff-preview">
      <h3 className="config-confirm-diff__title">معاينة الفروقات</h3>
      {rows.length > 0 ? (
        <table className="config-confirm-diff__table">
          <thead>
            <tr>
              <th>الحقل</th>
              <th>قبل</th>
              <th>بعد</th>
            </tr>
          </thead>
          <tbody>
            {rows.map((row) => (
              <tr key={row.key} data-testid={`config-diff-row-${row.key}`}>
                <td>{row.label}</td>
                <td>{row.oldValue}</td>
                <td>{row.newValue}</td>
              </tr>
            ))}
          </tbody>
        </table>
      ) : (
        <EmptyState compact title="لا توجد فروقات" description={emptyMessage} />
      )}
    </div>
  );
}
