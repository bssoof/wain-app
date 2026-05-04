export type VenueWorkspaceReadSuccess<T> = {
  kind: "success";
  data: T;
  asOf: string;
  fetchedAt: string;
  source: string;
  stale: boolean;
};

export type VenueWorkspaceReadUnavailable = {
  kind: "unavailable";
  message: string;
  attemptedSource?: string;
};

export type VenueWorkspaceReadResult<T> =
  | VenueWorkspaceReadSuccess<T>
  | VenueWorkspaceReadUnavailable;
