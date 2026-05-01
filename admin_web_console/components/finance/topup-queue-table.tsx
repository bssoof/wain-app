"use client";

import { useState } from "react";

import { useRouter } from "next/navigation";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import {
  formatCurrency,
  formatDate,
  formatStatus,
  getStatusColorClass,
} from "@/lib/finance/read-model-formatters";
import type { TopUpReadData } from "@/lib/finance/finance-read-loader";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";
import { downloadCsv, generateCsvData } from "@/lib/finance/csv-export";
import { commandKey } from "@/lib/finance/build-command-requests";
import { getCommandRuntimeStateClass } from "@/lib/finance/command-ui";
import type { TopUpRequest } from "@/lib/finance/read-models";
import { buildTopUpActionAffordances } from "@/lib/finance/surface-affordances";

import { CommandRuntimeCallout } from "./command-runtime-callout";
import { TopUpConfirmationDialog, type TopUpPendingDecision } from "./topup-confirmation-dialog";
import { useFinanceCommands } from "./finance-command-provider";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";

const QUEUE_TITLE = "طلبات الشحن التي تنتظر القرار";

export function TopUpQueueTable({
  readResult,
}: {
  readResult: FinanceReadResult<TopUpReadData>;
}) {
  const router = useRouter();
  const { runCommand, getRuntimeState, getLastErrorMessage, session } =
    useFinanceCommands();
  const [pendingDecision, setPendingDecision] = useState<TopUpPendingDecision | null>(null);

  if (readResult.kind === "unavailable") {
    return (
      <div className="card">
        <h3>{QUEUE_TITLE}</h3>
        <p className="finance-read-inline-unavailable" role="alert">
          تعذر عرض طلبات الشحن: {readResult.message}
        </p>
      </div>
    );
  }

  const { pending } = readResult.data;

  if (pending.length === 0) {
    return (
      <div className="card">
        <h3>{QUEUE_TITLE}</h3>
        <p data-testid="finance-read-empty">لا توجد طلبات شحن تنتظر القرار الآن.</p>
      </div>
    );
  }

  const canExport = session.roles.some(
    (role) => role === "finance_admin" || role === "super_admin",
  );
  const queueTotal = formatQueueTotal(pending);
  const latestRequest = findLatestRequest(pending);

  const onExportCsv = () => {
    const headers = [
      "رقم الطلب",
      "صاحب الطلب",
      "معرّف المالك",
      "المبلغ",
      "العملة",
      "الحالة",
      "تاريخ الطلب",
    ];
    const rows = pending.map((req) => [
      req.id,
      req.userName || "",
      req.userId || "",
      req.amount,
      req.currency,
      req.status,
      req.createdAt,
    ]);
    const csv = generateCsvData(headers, rows);
    downloadCsv(`topup-queue-${new Date().toISOString().slice(0, 10)}.csv`, csv);
  };

  return (
    <section className="card finance-queue-shell" dir="rtl" lang="ar">
      <div className="finance-section-header">
        <div className="finance-section-heading">
          <h3 className="dashboard-kpi__title">{QUEUE_TITLE}</h3>
          <p className="muted-text">
            راجع صاحب الطلب والمبلغ قبل اعتماد الشحن أو رفضه.
          </p>
        </div>
        {canExport && (
          <button
            type="button"
            className="action-button action-button-secondary"
            onClick={onExportCsv}
          >
            تنزيل الجدول
          </button>
        )}
      </div>

      <div className="finance-queue-summary" data-testid="finance-topup-summary">
        <div className="finance-queue-summary__item">
          <span className="muted-text">عدد الطلبات</span>
          <strong>{pending.length}</strong>
        </div>
        <div className="finance-queue-summary__item">
          <span className="muted-text">إجمالي المبالغ</span>
          <strong>{queueTotal}</strong>
        </div>
        <div className="finance-queue-summary__item">
          <span className="muted-text">آخر طلب</span>
          <strong>{latestRequest ? formatDate(latestRequest.createdAt) : "غير متاح"}</strong>
        </div>
      </div>

      <DataTable density="compact">
          <thead>
            <tr>
              <th>رقم الطلب</th>
              <th>صاحب الطلب</th>
              <th>المبلغ</th>
              <th>الحالة</th>
              <th>تاريخ الطلب</th>
              <th>القرار</th>
            </tr>
          </thead>
          <tbody>
            {pending.map((request) => {
              const approveKey = commandKey("approve_topup", request.id);
              const rejectKey = commandKey("reject_topup", request.id);
              const actions = buildTopUpActionAffordances(session, {
                approve_topup: getRuntimeState(approveKey),
                reject_topup: getRuntimeState(rejectKey),
              });
              const canMutate = actions.approve.visible || actions.reject.visible;
              const visibleCapability = actions.approve.visible
                ? actions.approve.requiredCapability
                : actions.reject.requiredCapability;

              const openApproveConfirm = () => {
                setPendingDecision({
                  action: "approve_topup",
                  request,
                  runtimeKey: approveKey,
                });
              };

              const openRejectConfirm = () => {
                setPendingDecision({
                  action: "reject_topup",
                  request,
                  runtimeKey: rejectKey,
                });
              };

              return (
                <tr key={request.id}>
                  <td>
                    <div className="finance-table-primary">
                      <strong>{request.id}</strong>
                      <span className="muted-text">
                        مرجع الدفع: {request.providerReference || "غير متاح"}
                      </span>
                    </div>
                  </td>
                  <td>
                    <strong>{request.userName || "صاحب طلب غير معروف"}</strong>
                    <br />
                    <span className="muted-text">معرّف صاحب الطلب: {request.userId}</span>
                    {request.venueId ? (
                      <>
                        <br />
                        <span className="muted-text">معرّف الجهة: {request.venueId}</span>
                      </>
                    ) : null}
                  </td>
                  <td>
                    <strong>{formatCurrency(request.amount, request.currency)}</strong>
                    <br />
                    <span className="muted-text">{formatCurrencyName(request.currency)}</span>
                  </td>
                  <td>
                    <StatusBadge className={getStatusColorClass(request.status)}>
                      {formatStatus(request.status)}
                    </StatusBadge>
                  </td>
                  <td>{formatDate(request.createdAt)}</td>
                  <td>
                    {canMutate ? (
                      <div className="command-actions">
                        <div className="command-actions__row">
                          {actions.approve.visible ? (
                            <button
                              type="button"
                              className="action-button"
                              data-testid={`finance-topup-${request.id}-approve`}
                              disabled={!actions.approve.enabled}
                              {...(getRuntimeState(approveKey) === "pending" ? { "aria-busy": true } : {})}
                              onClick={openApproveConfirm}
                            >
                              {actions.approve.label}
                            </button>
                          ) : null}
                          {actions.reject.visible ? (
                            <button
                              type="button"
                              className="action-button action-button-secondary"
                              data-testid={`finance-topup-${request.id}-reject`}
                              disabled={!actions.reject.enabled}
                              {...(getRuntimeState(rejectKey) === "pending" ? { "aria-busy": true } : {})}
                              onClick={openRejectConfirm}
                            >
                              {actions.reject.label}
                            </button>
                          ) : null}
                        </div>
                        {actions.approve.visible ? (
                          <StatusBadge
                            className={getCommandRuntimeStateClass(
                              actions.approve.runtimeState,
                            )}
                          >
                            {actions.approve.label}: {actions.approve.statusText}
                          </StatusBadge>
                        ) : null}
                        {actions.reject.visible ? (
                          <StatusBadge
                            className={getCommandRuntimeStateClass(
                              actions.reject.runtimeState,
                            )}
                          >
                            {actions.reject.label}: {actions.reject.statusText}
                          </StatusBadge>
                        ) : null}
                        <CommandRuntimeCallout
                          state={actions.approve.runtimeState}
                          message={getLastErrorMessage(approveKey)}
                          onRetry={openApproveConfirm}
                          onRefresh={() => router.refresh()}
                        />
                        <CommandRuntimeCallout
                          state={actions.reject.runtimeState}
                          message={getLastErrorMessage(rejectKey)}
                          onRetry={openRejectConfirm}
                          onRefresh={() => router.refresh()}
                        />
                        <span className="muted-text">
                          الصلاحية المطلوبة: {localizeAdminLabel(visibleCapability)}
                        </span>
                      </div>
                    ) : (
                      <span className="muted-text">
                        هذا الدور يستطيع القراءة فقط، لذلك لا تظهر قرارات القبول أو الرفض.
                      </span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </DataTable>
        {pendingDecision && (
          <TopUpConfirmationDialog
            decision={pendingDecision}
            onCancel={() => setPendingDecision(null)}
            onConfirmExecute={async (builtRequest) => {
              const result = await runCommand(
                pendingDecision.runtimeKey,
                pendingDecision.action,
                builtRequest as any
              );
              if (result.ok) {
                setPendingDecision(null);
                router.refresh();
              }
            }}
            submissionState={getRuntimeState(pendingDecision.runtimeKey)}
            submissionError={getLastErrorMessage(pendingDecision.runtimeKey)}
          />
        )}
    </section>
  );
}

function formatQueueTotal(pending: TopUpRequest[]): string {
  const totals = pending.reduce<Record<TopUpRequest["currency"], number>>(
    (acc, request) => {
      acc[request.currency] += request.amount;
      return acc;
    },
    { ILS: 0, USD: 0 },
  );

  const parts = (Object.keys(totals) as TopUpRequest["currency"][])
    .filter((currency) => totals[currency] > 0)
    .map((currency) => formatCurrency(totals[currency], currency));

  return parts.length > 0 ? parts.join(" + ") : "0";
}

function findLatestRequest(pending: TopUpRequest[]): TopUpRequest | undefined {
  return pending.reduce<TopUpRequest | undefined>((latest, request) => {
    if (!latest) {
      return request;
    }

    return Date.parse(request.createdAt) > Date.parse(latest.createdAt)
      ? request
      : latest;
  }, undefined);
}

function formatCurrencyName(currency: TopUpRequest["currency"]): string {
  return currency === "ILS" ? "شيكل" : "دولار";
}
