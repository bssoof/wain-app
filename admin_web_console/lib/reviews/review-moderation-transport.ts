import type {
  ReviewModerationAction,
  ReviewModerationCommandRequest,
  ReviewModerationCommandResponse,
} from "./review-moderation-contracts";

export type ReviewModerationTransportSuccess = {
  ok: true;
  data: ReviewModerationCommandResponse;
  correlationId?: string;
};

export type ReviewModerationTransportFailure = {
  ok: false;
  error: unknown;
  correlationId?: string;
};

export type ReviewModerationTransportResult =
  | ReviewModerationTransportSuccess
  | ReviewModerationTransportFailure;

export type ReviewModerationTransport = {
  execute(
    action: ReviewModerationAction,
    request: ReviewModerationCommandRequest,
  ): Promise<ReviewModerationTransportResult>;
};
