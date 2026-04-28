export type VenueDirectoryReadSuccess<T> = {
  kind: "success";
  data: T;
  asOf: string;
  fetchedAt: string;
  source: string;
  stale: boolean;
};

export type VenueDirectoryReadUnavailable = {
  kind: "unavailable";
  message: string;
  attemptedSource?: string;
};

export type VenueDirectoryReadResult<T> =
  | VenueDirectoryReadSuccess<T>
  | VenueDirectoryReadUnavailable;
