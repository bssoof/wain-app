export type FinanceReadSuccess<T> = {
  kind: "success";
  data: T;
  /** When the upstream snapshot claims the data was current */
  asOf: string;
  /** When this process fetched or materialized the snapshot */
  fetchedAt: string;
  /** Operator-visible; never omit — surfaces data-source honesty */
  source: string;
  stale: boolean;
};

export type FinanceReadUnavailable = {
  kind: "unavailable";
  message: string;
  attemptedSource?: string;
};

export type FinanceReadResult<T> = FinanceReadSuccess<T> | FinanceReadUnavailable;
