"use client";

import { useRouter } from "next/navigation";
import { useMemo, useState } from "react";

import { localizeAdminLabel } from "@/lib/admin/admin-localization";
import type { LedgerReadData } from "@/lib/finance/finance-read-loader";
import type { FinanceReadResult } from "@/lib/finance/finance-read-types";
import {
  formatCurrency,
  formatDate,
  formatStatus,
} from "@/lib/finance/read-model-formatters";
import { downloadCsv, generateCsvData } from "@/lib/finance/csv-export";
import {
  buildReverseWalletEntryRequest,
  commandKey,
} from "@/lib/finance/build-command-requests";
import { getCommandRuntimeStateClass } from "@/lib/finance/command-ui";
import { buildWalletEntryReversalAffordance } from "@/lib/finance/surface-affordances";
import { useToast } from "@/components/shared/ui/toast";
import type {
  WalletLedgerEntry,
  WalletLedgerEntryType,
} from "@/lib/finance/read-models";

import { CommandRuntimeCallout } from "./command-runtime-callout";
import { useFinanceCommands } from "./finance-command-provider";
import { DataTable } from "../shared/data-table";
import {
  FilterField,
  FilterSelect,
  FilterToolbar,
  type ActiveFilterChip,
} from "../shared/filter-toolbar";
import { StatusBadge } from "../shared/status-badge";

const LEDGER_TITLE = "سجل عمليات المحفظة";
type LedgerTypeFilter = WalletLedgerEntryType | "all";
type LedgerCurrencyFilter = WalletLedgerEntry["currency"] | "all";

export function WalletAuditActions({
  entries,
  canExport,
}: {
  entries: WalletLedgerEntry[];
  canExport: boolean;
}) {
  const toast = useToast();

  if (!canExport || entries.length === 0) {
    return null;
  }

  const onExportCsv = () => {
    try {
      const headers = [
        "رقم العملية",
        "صاحب الحساب",
        "النوع",
        "المبلغ",
        "العملة",
        "المرجع",
        "الوصف",
        "تاريخ العملية",
      ];
      const rows = entries.map((entry) => [
        entry.id,
        formatLedgerUserName(entry.userName),
        entry.type,
        entry.amount,
        entry.currency,
        formatLedgerReference(entry.reference),
        formatLedgerDescription(entry.description, entry.type),
        entry.createdAt,
      ]);
      const csv = generateCsvData(headers, rows);
      downloadCsv(`wallet-audit-${new Date().toISOString().slice(0, 10)}.csv`, csv);
      toast.show({
        severity: "success",
        title: "تم التصدير بنجاح",
        description: `${entries.length} سجل`,
      });
    } catch (error) {
      toast.show({
        severity: "danger",
        title: "فشل التصدير",
        description:
          error instanceof Error ? error.message : "حدث خطأ غير متوقع",
      });
    }
  };

  return (
    <div className="finance-page-actions">
      <button
        type="button"
        className="action-button action-button-secondary"
        onClick={onExportCsv}
      >
        تنزيل الجدول
      </button>
    </div>
  );
}

export function WalletAuditTable({
  readResult,
  loading = false,
}: {
  readResult: FinanceReadResult<LedgerReadData>;
  loading?: boolean;
}) {
  const router = useRouter();
  const [reversalOutcomeByEntryId, setReversalOutcomeByEntryId] = useState<
    Record<string, string>
  >({});
  const [searchValue, setSearchValue] = useState("");
  const [typeFilter, setTypeFilter] = useState<LedgerTypeFilter>("all");
  const [currencyFilter, setCurrencyFilter] =
    useState<LedgerCurrencyFilter>("all");
  const { runCommand, getRuntimeState, getLastErrorMessage, session } =
    useFinanceCommands();
  const entries = readResult.kind === "success" ? readResult.data.entries : [];

  const clearAllFilters = () => {
    setSearchValue("");
    setTypeFilter("all");
    setCurrencyFilter("all");
  };

  const activeFilters = useMemo(() => {
    const filters: ActiveFilterChip[] = [];

    if (searchValue.trim()) {
      filters.push({
        key: "search",
        label: "بحث",
        value: searchValue.trim(),
        onRemove: () => setSearchValue(""),
      });
    }

    if (typeFilter !== "all") {
      filters.push({
        key: "type",
        label: "النوع",
        value: formatStatus(typeFilter),
        onRemove: () => setTypeFilter("all"),
      });
    }

    if (currencyFilter !== "all") {
      filters.push({
        key: "currency",
        label: "العملة",
        value: formatCurrencyName(currencyFilter),
        onRemove: () => setCurrencyFilter("all"),
      });
    }

    return filters;
  }, [currencyFilter, searchValue, typeFilter]);

  const filteredEntries = useMemo(() => {
    const query = searchValue.trim().toLowerCase();

    return entries.filter((entry) => {
      const matchesSearch =
        query.length === 0 || ledgerEntryMatchesSearch(entry, query);
      const matchesType = typeFilter === "all" || entry.type === typeFilter;
      const matchesCurrency =
        currencyFilter === "all" || entry.currency === currencyFilter;

      return matchesSearch && matchesType && matchesCurrency;
    });
  }, [currencyFilter, entries, searchValue, typeFilter]);

  if (readResult.kind === "unavailable") {
    return (
      <div className="card">
        <h3>{LEDGER_TITLE}</h3>
        <p className="finance-read-inline-unavailable" role="alert">
          تعذر عرض {LEDGER_TITLE}: {readResult.message}
        </p>
      </div>
    );
  }
  const debitTotal = formatLedgerTotal(filteredEntries, ["debit"]);
  const creditAndReversalTotal = formatLedgerTotal(filteredEntries, [
    "credit",
    "reversal",
  ]);
  const latestEntry = findLatestEntry(filteredEntries);
  const hasActiveFilters = activeFilters.length > 0;

  return (
    <section className="card finance-queue-shell" dir="rtl" lang="ar">
      <div className="finance-section-header">
        <div className="finance-section-heading">
          <h3 className="dashboard-kpi__title">{LEDGER_TITLE}</h3>
          <p className="muted-text">
            راجع تفاصيل كل حركة قبل طلب التصحيح، خصوصًا الخصومات ذات الأثر المالي المباشر.
          </p>
        </div>
      </div>

      <div className="finance-queue-summary" data-testid="finance-ledger-summary">
        <div className="finance-queue-summary__item">
          <span className="muted-text">عدد العمليات</span>
          <strong>{filteredEntries.length}</strong>
        </div>
        <div className="finance-queue-summary__item">
          <span className="muted-text">إجمالي الخصم</span>
          <strong>{debitTotal}</strong>
        </div>
        <div className="finance-queue-summary__item">
          <span className="muted-text">إجمالي الإضافة</span>
          <strong>{creditAndReversalTotal}</strong>
        </div>
        <div className="finance-queue-summary__item">
          <span className="muted-text">آخر عملية</span>
          <strong>{latestEntry ? formatDate(latestEntry.createdAt) : "غير متاح"}</strong>
        </div>
      </div>

      <FilterToolbar
        activeFilters={activeFilters}
        onClearAll={hasActiveFilters ? clearAllFilters : undefined}
        onSearchChange={setSearchValue}
        searchPlaceholder="بحث..."
        searchValue={searchValue}
        testId="finance-ledger-filters"
      >
        <FilterField label="النوع">
          <FilterSelect
            aria-label="تصفية حسب النوع"
            onChange={(event) => setTypeFilter(event.target.value as LedgerTypeFilter)}
            value={typeFilter}
          >
            <option value="all">كل الأنواع</option>
            <option value="credit">إضافة</option>
            <option value="debit">خصم</option>
            <option value="reversal">تصحيح</option>
          </FilterSelect>
        </FilterField>
        <FilterField label="العملة">
          <FilterSelect
            aria-label="تصفية حسب العملة"
            onChange={(event) =>
              setCurrencyFilter(event.target.value as LedgerCurrencyFilter)
            }
            value={currencyFilter}
          >
            <option value="all">كل العملات</option>
            <option value="ILS">شيكل</option>
            <option value="USD">دولار</option>
          </FilterSelect>
        </FilterField>
      </FilterToolbar>

      {entries.length === 0 ? (
        <p className="muted-text" data-testid="finance-read-empty">
          لا توجد عمليات في نسخة البيانات الحالية.
        </p>
      ) : null}

      <DataTable<WalletLedgerEntry>
        density="compact"
        emptyState={{
          title: hasActiveFilters ? "لا توجد نتائج للفلتر الحالي" : "لا توجد بيانات",
          description: hasActiveFilters
            ? "جرب تعديل أو مسح الفلاتر"
            : "لا توجد عمليات في نسخة البيانات الحالية.",
          action: hasActiveFilters
            ? { label: "مسح الفلاتر", onClick: clearAllFilters }
            : undefined,
        }}
        loading={loading}
        loadingRowCount={8}
        rows={filteredEntries}
        stickyHeader
        testId="finance-ledger-table"
      >
          <thead>
            <tr>
              <th>رقم العملية</th>
              <th>صاحب الحساب</th>
              <th>النوع</th>
              <th>المبلغ</th>
              <th>المرجع</th>
              <th>تاريخ العملية</th>
              <th>تصحيح العملية</th>
            </tr>
          </thead>
          <tbody>
            {filteredEntries.map((entry) => {
              const runtimeKey = commandKey("reverse_wallet_entry", entry.id);
              const affordance = buildWalletEntryReversalAffordance(
                session,
                entry,
                getRuntimeState(runtimeKey),
              );

              const onReverse = async () => {
                const result = await runCommand(
                  runtimeKey,
                  "reverse_wallet_entry",
                  buildReverseWalletEntryRequest(entry),
                );
                if (result.ok) {
                  if (result.data.status === "pending_second_approval") {
                    const approvalRequestId = result.data.reversalRequestId ?? "unknown";
                    setReversalOutcomeByEntryId((prev) => ({
                      ...prev,
                      [entry.id]: `ينتظر موافقة ثانية (${approvalRequestId}).`,
                    }));
                    return;
                  }

                  setReversalOutcomeByEntryId((prev) => ({
                    ...prev,
                    [entry.id]: `تم تنفيذ التصحيح (${result.data.reversalEntryId ?? "غير متاح"}).`,
                  }));
                  router.refresh();
                }
              };

              return (
                <tr key={entry.id}>
                  <td>
                    <div className="finance-table-primary">
                      <strong>{entry.id}</strong>
                      <span className="muted-text">
                        الجهة: {formatLedgerVenue(entry.venueId)}
                      </span>
                    </div>
                  </td>
                  <td>
                    <strong>{formatLedgerUserName(entry.userName)}</strong>
                    <br />
                    <span className="muted-text">معرّف الحساب: {entry.userId}</span>
                  </td>
                  <td>
                    <span
                      className={`finance-status-badge finance-status-badge--${entry.type}`}
                    >
                      {formatStatus(entry.type)}
                    </span>
                  </td>
                  <td>
                    <strong
                      className={`finance-amount-cell ${
                        entry.type === "debit"
                          ? "finance-amount-cell--negative"
                          : "finance-amount-cell--positive"
                      }`}
                    >
                      {formatCurrency(entry.amount, entry.currency)}
                    </strong>
                    <br />
                    <span className="muted-text">{formatCurrencyName(entry.currency)}</span>
                  </td>
                  <td>
                    <strong>{formatLedgerReference(entry.reference)}</strong>
                    <br />
                    <span className="muted-text">
                      {formatLedgerDescription(entry.description, entry.type)}
                    </span>
                  </td>
                  <td>{formatDate(entry.createdAt)}</td>
                  <td>
                    {!affordance ? (
                      <span className="muted-text">
                        لا يوجد إجراء تصحيح متاح لهذا النوع من العمليات.
                      </span>
                    ) : !affordance.visible ? (
                      <span className="muted-text">
                        هذا الدور يستطيع القراءة فقط، لذلك لا يظهر إجراء التصحيح.
                      </span>
                    ) : (
                      <div className="command-actions">
                        <button
                          type="button"
                          className="action-button"
                          disabled={!affordance.enabled}
                          {...(getRuntimeState(runtimeKey) === "pending" ? { "aria-busy": true } : {})}
                          onClick={() => void onReverse()}
                        >
                          {affordance.label}
                        </button>
                        <StatusBadge
                          className={getCommandRuntimeStateClass(
                            affordance.runtimeState,
                          )}
                        >
                          {affordance.statusText}
                        </StatusBadge>
                        <CommandRuntimeCallout
                          state={affordance.runtimeState}
                          message={getLastErrorMessage(runtimeKey)}
                          onRetry={() => void onReverse()}
                          onRefresh={() => router.refresh()}
                        />
                        {reversalOutcomeByEntryId[entry.id] ? (
                          <span
                            className="muted-text"
                            data-testid={`finance-reversal-outcome-${entry.id}`}
                          >
                            {reversalOutcomeByEntryId[entry.id]}
                          </span>
                        ) : null}
                        <span className="muted-text">
                          الصلاحية المطلوبة: {localizeAdminLabel(affordance.requiredCapability)}
                        </span>
                      </div>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </DataTable>
    </section>
  );
}

function formatLedgerTotal(
  entries: WalletLedgerEntry[],
  includeTypes: WalletLedgerEntryType[],
): string {
  const totals = entries.reduce<Record<WalletLedgerEntry["currency"], number>>(
    (acc, entry) => {
      if (includeTypes.includes(entry.type)) {
        acc[entry.currency] += entry.amount;
      }
      return acc;
    },
    { ILS: 0, USD: 0 },
  );

  const parts = (Object.keys(totals) as WalletLedgerEntry["currency"][])
    .filter((currency) => totals[currency] > 0)
    .map((currency) => formatCurrency(totals[currency], currency));

  return parts.length > 0 ? parts.join(" + ") : "0";
}

function findLatestEntry(entries: WalletLedgerEntry[]): WalletLedgerEntry | undefined {
  return entries.reduce<WalletLedgerEntry | undefined>((latest, entry) => {
    if (!latest) {
      return entry;
    }

    return Date.parse(entry.createdAt) > Date.parse(latest.createdAt)
      ? entry
      : latest;
  }, undefined);
}

function ledgerEntryMatchesSearch(entry: WalletLedgerEntry, query: string): boolean {
  return [
    entry.id,
    entry.venueId,
    entry.userId,
    entry.userName,
    entry.type,
    entry.amount.toString(),
    entry.currency,
    entry.reference,
    entry.description,
  ].some((value) => value?.toLowerCase().includes(query));
}

function formatCurrencyName(currency: WalletLedgerEntry["currency"]): string {
  return currency === "ILS" ? "شيكل" : "دولار";
}

function containsLatinText(value: string | undefined): boolean {
  return /[A-Za-z]/.test(value ?? "");
}

function formatLedgerUserName(userName: string | undefined): string {
  if (!userName) {
    return "صاحب حساب غير معروف";
  }

  const normalized = userName.trim().toLowerCase();

  if (normalized.includes("admin operator")) {
    return "مشغّل إداري";
  }

  if (normalized.includes("local admin")) {
    return "مسؤول محلي";
  }

  if (containsLatinText(userName)) {
    return "صاحب حساب";
  }

  return userName;
}

function formatLedgerVenue(venueId: string | undefined): string {
  if (!venueId) {
    return "غير متاحة";
  }

  const normalized = venueId.trim().toLowerCase();
  if (normalized.includes("local") || normalized.includes("emulator")) {
    return "جهة محلية للتجربة";
  }

  return containsLatinText(venueId) ? "جهة محفوظة" : venueId;
}

function formatLedgerReference(reference: string | undefined): string {
  if (!reference) {
    return "بدون مرجع";
  }

  const normalized = reference.trim().toLowerCase();

  if (normalized.includes("topup") || normalized.includes("top-up")) {
    return "طلب شحن";
  }

  if (normalized.includes("reversal")) {
    return "تصحيح عملية";
  }

  if (normalized.includes("story")) {
    return "قصة";
  }

  if (normalized.includes("order")) {
    return "طلب";
  }

  if (normalized.includes("payout")) {
    return "دفعة";
  }

  return containsLatinText(reference) ? "مرجع محفوظ" : reference;
}

function formatLedgerDescription(
  description: string | undefined,
  type: WalletLedgerEntry["type"],
): string {
  if (!description) {
    return "بدون وصف";
  }

  const normalized = description.trim().toLowerCase();

  if (normalized.includes("approved top-up request")) {
    return "طلب شحن معتمد";
  }

  if (normalized.includes("top-up") || normalized.includes("topup")) {
    return "إضافة رصيد من طلب شحن";
  }

  if (normalized.includes("story promotion")) {
    return "ترويج قصة";
  }

  if (normalized.includes("order settlement")) {
    return "تسوية طلب";
  }

  if (normalized.includes("wallet adjustment")) {
    return "تعديل محفظة";
  }

  if (normalized.includes("approved reversal")) {
    return "تصحيح معتمد";
  }

  if (normalized.includes("large payout")) {
    return "دفعة كبيرة";
  }

  return containsLatinText(description) ? formatStatus(type) : description;
}
