import type {
  ContentModerationAction,
  ModerateOfferCommand,
  ModerateStoryCommand,
  ContentModerationResult,
} from "./content-command-contracts";

export type ContentCommandTransportSuccess = {
  ok: true;
  data: ContentModerationResult;
  correlationId?: string;
};

export type ContentCommandTransportFailure = {
  ok: false;
  error: unknown;
  correlationId?: string;
};

export type ContentCommandTransportResult =
  | ContentCommandTransportSuccess
  | ContentCommandTransportFailure;

export interface ContentCommandTransport {
  moderateOffer(command: ModerateOfferCommand): Promise<ContentModerationResult>;
  moderateStory(command: ModerateStoryCommand): Promise<ContentModerationResult>;
}

export type ContentModerationTransport = {
  executeOffer(
    action: ContentModerationAction,
    command: ModerateOfferCommand,
  ): Promise<ContentCommandTransportResult>;
  executeStory(
    action: ContentModerationAction,
    command: ModerateStoryCommand,
  ): Promise<ContentCommandTransportResult>;
};
