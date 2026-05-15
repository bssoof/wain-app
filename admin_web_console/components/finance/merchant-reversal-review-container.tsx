"use client";

import { useCallback, useEffect } from "react";

import {
  useFinanceCommands,
} from "@/components/finance/finance-command-provider";
import { MerchantReversalReviewPanel } from "@/components/finance/merchant-reversal-review-panel";
import { useToast } from "@/components/shared/ui/toast";
import { canRenderAction } from "@/lib/auth/guard-api";
import {
  mapReviewMerchantReversalError,
  useReviewMerchantReversal,
} from "@/lib/finance/use-review-merchant-reversal";
import { useMerchantReversalRequests } from "@/lib/finance/use-merchant-reversal-requests";

type MerchantReversalReviewContainerProps = {
  onPendingCountChange?: (count: number) => void;
};

export function MerchantReversalReviewContainer({
  onPendingCountChange,
}: MerchantReversalReviewContainerProps) {
  const { session } = useFinanceCommands();
  const { requests, isLoading, error, refresh } = useMerchantReversalRequests();
  const { execute } = useReviewMerchantReversal();
  const toast = useToast();
  const canReview = canRenderAction(session, "create_reversal");

  useEffect(() => {
    onPendingCountChange?.(requests.length);
  }, [onPendingCountChange, requests.length]);

  const handleApprove = useCallback(
    async (requestId: string, adminNote?: string) => {
      try {
        const result = await execute({
          requestId,
          decision: "approve",
          adminNote,
        });

        if (result.status === "approved_and_executed") {
          toast.show({ severity: "success", title: "تم تنفيذ التصحيح" });
        } else if (result.status === "pending_second_approval") {
          const roleLabel =
            result.requiredSecondApproverRole === "super_admin"
              ? "super_admin"
              : "finance_admin";
          toast.show({
            severity: "info",
            title: `تم اعتماد الطلب — بانتظار موافقة ثانية من ${roleLabel}`,
          });
        }

        refresh();
      } catch (reviewError) {
        const message = mapReviewMerchantReversalError(reviewError);
        toast.show({ severity: "danger", title: message });
        throw new Error(message);
      }
    },
    [execute, refresh, toast],
  );

  const handleReject = useCallback(
    async (
      requestId: string,
      rejectionReason: string,
      adminNote?: string,
    ) => {
      try {
        await execute({
          requestId,
          decision: "reject",
          rejectionReason,
          adminNote,
        });
        toast.show({ severity: "success", title: "تم رفض الطلب" });
        refresh();
      } catch (reviewError) {
        const message = mapReviewMerchantReversalError(reviewError);
        toast.show({ severity: "danger", title: message });
        throw new Error(message);
      }
    },
    [execute, refresh, toast],
  );

  return (
    <MerchantReversalReviewPanel
      canReview={canReview}
      error={error}
      isLoading={isLoading}
      onApprove={handleApprove}
      onRefresh={refresh}
      onReject={handleReject}
      requests={requests}
    />
  );
}
