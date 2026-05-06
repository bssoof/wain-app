"use client";

import { useMemo, useState } from "react";

import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import {
  formatCurrency,
  formatDate,
  formatStatus,
  getStatusColorClass,
} from "@/lib/finance/read-model-formatters";
import type {
  VenueOffersReadData,
  VenueReviewsReadData,
  VenueStoriesReadData,
  VenueWalletReadData,
  VenueWorkspaceReadBundle,
} from "@/lib/venues/venue-workspace-read-loader";
import type { VenueWorkspaceTabKey } from "@/lib/venues/venue-workspace-models";
import type { VenueWorkspaceReadResult } from "@/lib/venues/venue-workspace-read-types";

import { VenueWorkspaceHeader } from "./venue-workspace-header";
import { VenueWorkspaceReadBanner } from "./venue-workspace-read-banner";
import { DataTable } from "../shared/data-table";
import { StatusBadge } from "../shared/status-badge";
import { EmptyState } from "../shared/ui/empty-state";

const TABS: Array<{ key: VenueWorkspaceTabKey; label: string }> = [
  { key: "wallet", label: "المحفظة" },
  { key: "offers", label: "العروض" },
  { key: "stories", label: "القصص" },
  { key: "reviews", label: "المراجعات" },
];

const TAB_LABELS: Record<VenueWorkspaceTabKey, string> = {
  wallet: "المحفظة",
  offers: "العروض",
  stories: "القصص",
  reviews: "المراجعات",
};

type AnyTabRead =
  | VenueWorkspaceReadResult<VenueWalletReadData>
  | VenueWorkspaceReadResult<VenueOffersReadData>
  | VenueWorkspaceReadResult<VenueStoriesReadData>
  | VenueWorkspaceReadResult<VenueReviewsReadData>;

export function VenueWorkspaceShell({
  venueId,
  readBundle,
}: {
  venueId: string;
  readBundle: VenueWorkspaceReadBundle;
}) {
  const [activeTab, setActiveTab] = useState<VenueWorkspaceTabKey>("wallet");

  const activeRead = useMemo<AnyTabRead>(() => {
    if (activeTab === "wallet") {
      return readBundle.wallet;
    }
    if (activeTab === "offers") {
      return readBundle.offers;
    }
    if (activeTab === "stories") {
      return readBundle.stories;
    }
    return readBundle.reviews;
  }, [activeTab, readBundle]);

  return (
    <div className="venue-workspace-shell" data-testid="venue-workspace-shell" dir="rtl" lang="ar">
      <VenueWorkspaceHeader venueId={venueId} context={readBundle.context} />

      <div className="card venue-workspace-tabs-card">
        <div className="venue-workspace-tabs" role="tablist" aria-label="أقسام تفاصيل الجهة">
          {TABS.map((tab) => {
            const isActive = activeTab === tab.key;
            return (
              <button
                key={tab.key}
                id={`venue-workspace-tab-${tab.key}`}
                type="button"
                role="tab"
                {...{ "aria-selected": isActive }}
                aria-controls={`venue-workspace-panel-${tab.key}`}
                className={`venue-workspace-tab ${isActive ? "active" : ""}`}
                data-testid={`venue-workspace-tab-${tab.key}`}
                onClick={() => setActiveTab(tab.key)}
              >
                {tab.label}
              </button>
            );
          })}
        </div>

        <div
          id={`venue-workspace-panel-${activeTab}`}
          role="tabpanel"
          aria-labelledby={`venue-workspace-tab-${activeTab}`}
          className="venue-workspace-panel"
          data-testid={`venue-workspace-panel-${activeTab}`}
        >
          <p className="muted-text" data-testid="venue-workspace-read-only-note">
            هذه الأقسام للعرض فقط حاليًا.
          </p>
          <VenueWorkspaceReadBanner
            result={activeRead as VenueWorkspaceReadResult<unknown>}
            label={`قراءة قسم ${getTabLabel(activeTab)}`}
            tabKey={activeTab}
          />
          {renderTabContent(activeTab, activeRead)}
        </div>
      </div>
    </div>
  );
}

function renderTabContent(
  tab: VenueWorkspaceTabKey,
  result:
    | VenueWorkspaceReadResult<VenueWalletReadData>
    | VenueWorkspaceReadResult<VenueOffersReadData>
    | VenueWorkspaceReadResult<VenueStoriesReadData>
    | VenueWorkspaceReadResult<VenueReviewsReadData>,
) {
  if (result.kind === "unavailable") {
    return (
      <p
        className="finance-read-inline-unavailable"
        role="alert"
        data-testid={`venue-tab-unavailable-${tab}`}
      >
        تعذر عرض قسم {getTabLabel(tab)}: {localizeAdminMessage(result.message) ?? result.message}
      </p>
    );
  }

  if (tab === "wallet") {
    const { entries } = result.data as VenueWalletReadData;
    if (entries.length === 0) {
      return renderWorkspaceEmptyState(
        "venue-tab-empty-wallet",
        "لا توجد عمليات محفظة",
        "لا توجد عمليات محفظة في البيانات الحالية.",
      );
    }

    return (
      <DataTable density="comfortable" scrollClassName="venue-workspace-table-card" stickyHeader>
          <thead>
            <tr>
              <th>رقم العملية</th>
              <th>النوع</th>
              <th>المبلغ</th>
              <th>الوصف</th>
              <th>تاريخ العملية</th>
            </tr>
          </thead>
          <tbody>
            {entries.map((entry) => (
              <tr key={entry.id}>
                <td>{entry.id}</td>
                <td>
                  <StatusBadge className={getStatusColorClass(entry.type)}>
                    {formatStatus(entry.type)}
                  </StatusBadge>
                </td>
                <td>{formatCurrency(entry.amount, entry.currency)}</td>
                <td>{entry.description}</td>
                <td>{formatDate(entry.createdAt)}</td>
              </tr>
            ))}
          </tbody>
        </DataTable>
    );
  }

  if (tab === "offers") {
    const { items } = result.data as VenueOffersReadData;
    if (items.length === 0) {
      return renderWorkspaceEmptyState(
        "venue-tab-empty-offers",
        "لا توجد عروض",
        "لا توجد عروض في البيانات الحالية.",
      );
    }

    return (
      <DataTable density="comfortable" scrollClassName="venue-workspace-table-card" stickyHeader>
          <thead>
            <tr>
              <th>العرض</th>
              <th>الحالة</th>
              <th>يبدأ</th>
              <th>ينتهي</th>
            </tr>
          </thead>
          <tbody>
            {items.map((offer) => (
              <tr key={offer.id}>
                <td>
                  <strong>{offer.title}</strong>
                  <br />
                  <span className="muted-text">{offer.id}</span>
                </td>
                <td>
                  <StatusBadge className={getStatusColorClass(offer.status)}>
                    {formatStatus(offer.status)}
                  </StatusBadge>
                </td>
                <td>{formatDate(offer.startsAt)}</td>
                <td>{formatDate(offer.endsAt)}</td>
              </tr>
            ))}
          </tbody>
        </DataTable>
    );
  }

  if (tab === "stories") {
    const { items } = result.data as VenueStoriesReadData;
    if (items.length === 0) {
      return renderWorkspaceEmptyState(
        "venue-tab-empty-stories",
        "لا توجد قصص",
        "لا توجد قصص في البيانات الحالية.",
      );
    }

    return (
      <DataTable density="comfortable" scrollClassName="venue-workspace-table-card" stickyHeader>
          <thead>
            <tr>
              <th>القصة</th>
              <th>الحالة</th>
            <th>ينتهي بتاريخ</th>
            </tr>
          </thead>
          <tbody>
            {items.map((story) => (
              <tr key={story.id}>
                <td>
                  <strong>{story.caption}</strong>
                  <br />
                  <span className="muted-text">{story.id}</span>
                </td>
                <td>
                  <StatusBadge className={getStatusColorClass(story.status)}>
                    {formatStatus(story.status)}
                  </StatusBadge>
                </td>
                <td>{formatDate(story.expiresAt)}</td>
              </tr>
            ))}
          </tbody>
        </DataTable>
    );
  }

  const { items } = result.data as VenueReviewsReadData;
  if (items.length === 0) {
    return renderWorkspaceEmptyState(
      "venue-tab-empty-reviews",
      "لا توجد مراجعات",
      "لا توجد مراجعات في البيانات الحالية.",
    );
  }

  return (
    <DataTable density="comfortable" scrollClassName="venue-workspace-table-card" stickyHeader>
        <thead>
          <tr>
            <th>المراجعة</th>
            <th>التقييم</th>
            <th>الحالة</th>
            <th>تاريخ المراجعة</th>
          </tr>
        </thead>
        <tbody>
          {items.map((review) => (
            <tr key={review.id}>
              <td>
                <strong>{review.authorName}</strong>
                <br />
                <span className="muted-text">{review.snippet}</span>
              </td>
              <td>{review.rating}/5</td>
              <td>
                <StatusBadge className={getStatusColorClass(review.status)}>
                  {formatStatus(review.status)}
                </StatusBadge>
              </td>
              <td>{formatDate(review.createdAt)}</td>
            </tr>
          ))}
        </tbody>
      </DataTable>
  );
}

function renderWorkspaceEmptyState(
  testId: string,
  title: string,
  description: string,
) {
  return (
    <div className="venue-workspace-empty-state" data-testid={testId}>
      <EmptyState compact title={title} description={description} />
    </div>
  );
}

function getTabLabel(tab: VenueWorkspaceTabKey): string {
  return TAB_LABELS[tab] ?? formatStatus(tab);
}
