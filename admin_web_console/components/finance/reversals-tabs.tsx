"use client";

import { useState } from "react";

import { MerchantReversalReviewContainer } from "@/components/finance/merchant-reversal-review-container";
import { ReversalApprovalPanel } from "@/components/finance/reversal-approval-panel";

type ReversalTab = "merchant" | "admin";

export function ReversalsTabs() {
  const [activeTab, setActiveTab] = useState<ReversalTab>("merchant");
  const [pendingMerchantCount, setPendingMerchantCount] = useState(0);

  return (
    <section className="finance-tabbed-panel" dir="rtl" lang="ar">
      <div aria-label="أنواع طلبات العكس" className="finance-tabs" role="tablist">
        <button
          aria-controls="merchant-reversal-tab"
          aria-selected={activeTab === "merchant"}
          className="finance-tab"
          id="merchant-reversal-tab-button"
          onClick={() => setActiveTab("merchant")}
          role="tab"
          type="button"
        >
          طلبات التجار
          {pendingMerchantCount > 0 ? (
            <span className="finance-tab__badge">{pendingMerchantCount}</span>
          ) : null}
        </button>
        <button
          aria-controls="admin-reversal-tab"
          aria-selected={activeTab === "admin"}
          className="finance-tab"
          id="admin-reversal-tab-button"
          onClick={() => setActiveTab("admin")}
          role="tab"
          type="button"
        >
          طلبات إدارية
        </button>
      </div>

      <div
        aria-labelledby="merchant-reversal-tab-button"
        hidden={activeTab !== "merchant"}
        id="merchant-reversal-tab"
        role="tabpanel"
      >
        <MerchantReversalReviewContainer
          onPendingCountChange={setPendingMerchantCount}
        />
      </div>

      <div
        aria-labelledby="admin-reversal-tab-button"
        hidden={activeTab !== "admin"}
        id="admin-reversal-tab"
        role="tabpanel"
      >
        <ReversalApprovalPanel />
      </div>
    </section>
  );
}
