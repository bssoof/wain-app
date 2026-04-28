import type {
  ConfigCommandRequestMap,
  ConfigCommandResponseMap,
  ConfigCommandType,
} from "./config-command-contracts";

export type ConfigCommandTransportSuccess<T extends ConfigCommandType> = {
  ok: true;
  data: ConfigCommandResponseMap[T];
  correlationId?: string;
};

export type ConfigCommandTransportFailure = {
  ok: false;
  error: unknown;
  correlationId?: string;
};

export type ConfigCommandTransportResult<T extends ConfigCommandType> =
  | ConfigCommandTransportSuccess<T>
  | ConfigCommandTransportFailure;

export type ConfigCommandTransport = {
  execute<T extends ConfigCommandType>(
    command: T,
    request: ConfigCommandRequestMap[T],
  ): Promise<ConfigCommandTransportResult<T>>;
};
