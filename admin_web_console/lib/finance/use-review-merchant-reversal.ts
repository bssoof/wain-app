"use client";

import {
  useFinanceCommands,
} from "@/components/finance/finance-command-provider";
import {
  buildReviewMerchantReversalRequest,
  commandKey,
} from "@/lib/finance/build-command-requests";
import type {
  ReviewMerchantReversalCommandResponse,
} from "@/lib/finance/command-contracts";

type ReviewMerchantReversalInput =
  | {
      requestId: string;
      decision: "approve";
      adminNote?: string;
    }
  | {
      requestId: string;
      decision: "reject";
      rejectionReason: string;
      adminNote?: string;
    };

function extractErrorText(error: unknown): string {
  if (typeof error === "string") return error;
  if (error instanceof Error) return error.message;
  if (error && typeof error === "object") {
    const candidate = error as { code?: unknown; message?: unknown };
    if (typeof candidate.message === "string") return candidate.message;
    if (typeof candidate.code === "string") return candidate.code;
  }
  return "";
}

export function mapReviewMerchantReversalError(error: unknown): string {
  const text = extractErrorText(error);
  const normalized = text.toLowerCase().replace(/[\s-]+/g, "_");

  if (normalized.includes("request_not_found")) {
    return "الطلب غير موجود أو تم حذفه";
  }
  if (normalized.includes("request_not_pending_review")) {
    return "تمت مراجعة الطلب مسبقًا";
  }
  if (normalized.includes("rejection_reason_required")) {
    return "سبب الرفض مطلوب";
  }
  if (normalized.includes("entry_already_reversed")) {
    return "تم تصحيح هذه العملية من قِبل أدمن آخر";
  }
  if (
    normalized.includes("forbidden") ||
    normalized.includes("permission_denied")
  ) {
    return "ليس لديك صلاحية مراجعة هذا الطلب";
  }
  if (normalized.includes("invalid_review_arguments")) {
    return "البيانات المرسلة غير مكتملة";
  }
  if (normalized.includes("failed_precondition")) {
    return "تعذّر إكمال العملية — حاول لاحقًا";
  }
  if (text.trim()) {
    return text;
  }
  return "حدث خطأ غير متوقع";
}

export function useReviewMerchantReversal() {
  const { runCommand } = useFinanceCommands();

  async function execute(
    input: ReviewMerchantReversalInput,
  ): Promise<ReviewMerchantReversalCommandResponse> {
    try {
      const request =
        input.decision === "approve"
          ? buildReviewMerchantReversalRequest(
              {
                requestId: input.requestId,
                decision: "approve",
              },
              { adminNote: input.adminNote },
            )
          : buildReviewMerchantReversalRequest(
              {
                requestId: input.requestId,
                decision: "reject",
                rejectionReason: input.rejectionReason,
              },
              { adminNote: input.adminNote },
            );

      const result = await runCommand(
        commandKey("review_merchant_reversal", input.requestId),
        "review_merchant_reversal",
        request,
      );

      if (!result.ok) {
        throw new Error(mapReviewMerchantReversalError(result.error.message));
      }

      return result.data as ReviewMerchantReversalCommandResponse;
    } catch (error) {
      throw new Error(mapReviewMerchantReversalError(error));
    }
  }

  return { execute };
}
