import type {
  VenueCommandRequest,
  VenueCommandResult,
  VenueCommandType,
} from "./venue-command-contracts";

export type VenueCommandTransport = {
  execute<T extends VenueCommandType>(
    request: VenueCommandRequest & { action: T },
  ): Promise<VenueCommandResult<T>>;
};
