import type {
  MediaCommandRequestMap,
  MediaCommandResponseMap,
  MediaCommandType,
} from "./media-command-contracts";

export type MediaCommandTransportSuccess<T extends MediaCommandType> = {
  ok: true;
  data: MediaCommandResponseMap[T];
  correlationId?: string;
};

export type MediaCommandTransportFailure = {
  ok: false;
  error: unknown;
  correlationId?: string;
};

export type MediaCommandTransportResult<T extends MediaCommandType> =
  | MediaCommandTransportSuccess<T>
  | MediaCommandTransportFailure;

export type MediaCommandTransport = {
  execute<T extends MediaCommandType>(
    command: T,
    request: MediaCommandRequestMap[T],
  ): Promise<MediaCommandTransportResult<T>>;
};
