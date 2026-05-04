import {
  executeProxyCommand,
  type AdminCommandProxyTransportOptions,
} from "@/lib/admin-command-proxy/proxy-client";

import type {
  ReviewModerationAction,
  ReviewModerationCommandRequest,
  ReviewModerationCommandResponse,
} from "./review-moderation-contracts";
import type {
  ReviewModerationTransport,
  ReviewModerationTransportResult,
} from "./review-moderation-transport";

const DEFAULT_REVIEW_MODERATION_PROXY_ENDPOINT = "/api/admin/command/reviews";

export type ReviewModerationProxyTransportOptions = AdminCommandProxyTransportOptions;

export function createReviewModerationProxyTransport(
  options: ReviewModerationProxyTransportOptions = {},
): ReviewModerationTransport {
  const endpoint =
    options.endpoint?.trim() || DEFAULT_REVIEW_MODERATION_PROXY_ENDPOINT;

  return {
    async execute(
      action: ReviewModerationAction,
      request: ReviewModerationCommandRequest,
    ): Promise<ReviewModerationTransportResult> {
      const result = await executeProxyCommand<ReviewModerationCommandResponse>(
        {
          endpoint,
          fetchImpl: options.fetchImpl,
          resolveAuthToken: options.resolveAuthToken,
          resolveAppCheckToken: options.resolveAppCheckToken,
        },
        {
          action,
          request,
        },
        request.correlationId,
      );

      if (result.ok) {
        return {
          ok: true,
          correlationId: result.correlationId ?? request.correlationId,
          data: result.data,
        };
      }

      return {
        ok: false,
        correlationId: result.correlationId ?? request.correlationId,
        error: result.error,
      };
    },
  };
}
