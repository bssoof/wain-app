import type { AdminCapabilityKey, AdminRole } from "@/lib/navigation/admin-contract";

// -- Command types --

export const VENUE_COMMANDS = [
  "create_venue",
  "update_venue_profile",
  "update_venue_visibility",
  "update_venue_operational_status",
  "update_venue_subscription_status",
] as const;

export type VenueCommandType = (typeof VENUE_COMMANDS)[number];

// -- Status types --

export type VenueSubscriptionStatus = "active" | "expired" | "paused";
export type VenueVisibilityStatus = "visible" | "hidden";
export type VenueOperationalStatus = "active" | "suspended" | "archived";
export type VenueCurrency = "ILS" | "USD";

export type VenueHoursDayKey =
  | "monday"
  | "tuesday"
  | "wednesday"
  | "thursday"
  | "friday"
  | "saturday"
  | "sunday";

export type VenueHoursSlot = {
  open: string;
  close: string;
  spansMidnight?: boolean;
};

export type VenueHoursMap = Partial<Record<VenueHoursDayKey, VenueHoursSlot[]>>;

export type VenueTagsPayload = {
  mood?: string[];
  occasion?: string[];
  timeOfDay?: string[];
  meal?: string[];
};

// -- Error types --

export type VenueCommandErrorCode =
  | "unauthorized"
  | "forbidden"
  | "conflict"
  | "validation_error"
  | "unavailable";

export type VenueCommandErrorStatus = 401 | 403 | 409 | 422 | 503;

export type VenueCommandError = {
  code: VenueCommandErrorCode;
  status: VenueCommandErrorStatus;
  message: string;
  retryable: boolean;
  details?: Record<string, unknown>;
};

const ERROR_STATUS_BY_CODE: Record<VenueCommandErrorCode, VenueCommandErrorStatus> = {
  unauthorized: 401,
  forbidden: 403,
  conflict: 409,
  validation_error: 422,
  unavailable: 503,
};

const ERROR_RETRYABLE_BY_CODE: Record<VenueCommandErrorCode, boolean> = {
  unauthorized: false,
  forbidden: false,
  conflict: true,
  validation_error: false,
  unavailable: true,
};

export function isVenueCommandErrorCode(value: unknown): value is VenueCommandErrorCode {
  return (
    value === "unauthorized" ||
    value === "forbidden" ||
    value === "conflict" ||
    value === "validation_error" ||
    value === "unavailable"
  );
}

export function createVenueCommandError(
  code: VenueCommandErrorCode,
  message: string,
  details?: Record<string, unknown>,
): VenueCommandError {
  return {
    code,
    status: ERROR_STATUS_BY_CODE[code],
    message,
    retryable: ERROR_RETRYABLE_BY_CODE[code],
    details,
  };
}

// -- Base request --

export type VenueCommandRequestBase = {
  commandId: string;
  correlationId: string;
  reason: string;
  submittedAt: string;
};

// -- Expected states --

export type CreateVenueExpectedState = Record<string, never>;

export type UpdateVenueProfileExpectedState = {
  operational_status: "active";
};

export type UpdateVenueVisibilityExpectedState = {
  current_visibility: VenueVisibilityStatus;
  operational_status: VenueOperationalStatus;
};

export type UpdateVenueOperationalStatusExpectedState = {
  current_operational_status: VenueOperationalStatus;
};

export type UpdateVenueSubscriptionStatusExpectedState = {
  current_subscription_status: VenueSubscriptionStatus;
};

// -- Command requests --

export type CreateVenueCommandRequest = VenueCommandRequestBase & {
  action: "create_venue";
  nameAr: string;
  city: string;
  categories: string[];
  lat: number;
  lng: number;
  nameEn?: string;
  phone?: string;
  instagram?: string;
  whatsapp?: string;
  facebook?: string;
  website?: string;
  minPrice?: number;
  maxPrice?: number;
  currency?: VenueCurrency;
  photos?: string[];
  menuImages?: string[];
  hours?: VenueHoursMap;
  is24h?: boolean;
  tags?: VenueTagsPayload;
  transportEnabled?: boolean;
  transportPartnerIds?: string[];
  transportNotesAr?: string;
  transportNotesEn?: string;
};

export type UpdateVenueProfileCommandRequest = VenueCommandRequestBase & {
  action: "update_venue_profile";
  venueId: string;
  updates: {
    nameAr?: string;
    nameEn?: string;
    city?: string;
    categories?: string[];
    phone?: string;
    lat?: number;
    lng?: number;
    photos?: string[];
    menuImages?: string[];
  };
  expectedState: UpdateVenueProfileExpectedState;
};

export type UpdateVenueVisibilityCommandRequest = VenueCommandRequestBase & {
  action: "update_venue_visibility";
  venueId: string;
  newVisibility: VenueVisibilityStatus;
  expectedState: UpdateVenueVisibilityExpectedState;
};

export type UpdateVenueOperationalStatusCommandRequest = VenueCommandRequestBase & {
  action: "update_venue_operational_status";
  venueId: string;
  newStatus: VenueOperationalStatus;
  expectedState: UpdateVenueOperationalStatusExpectedState;
};

export type UpdateVenueSubscriptionStatusCommandRequest = VenueCommandRequestBase & {
  action: "update_venue_subscription_status";
  venueId: string;
  newStatus: VenueSubscriptionStatus;
  expectedState: UpdateVenueSubscriptionStatusExpectedState;
};

// -- Command responses --

export type CreateVenueCommandResponse = {
  action: "create_venue";
  venueId: string;
  status: "created";
  auditEventId: string;
  replay?: boolean;
};

export type UpdateVenueProfileCommandResponse = {
  action: "update_venue_profile";
  venueId: string;
  status: "updated";
  auditEventId: string;
  replay?: boolean;
};

export type UpdateVenueVisibilityCommandResponse = {
  action: "update_venue_visibility";
  venueId: string;
  newVisibility: VenueVisibilityStatus;
  status: "updated";
  auditEventId: string;
  replay?: boolean;
};

export type UpdateVenueOperationalStatusCommandResponse = {
  action: "update_venue_operational_status";
  venueId: string;
  newStatus: VenueOperationalStatus;
  status: "updated";
  auditEventId: string;
  replay?: boolean;
};

export type UpdateVenueSubscriptionStatusCommandResponse = {
  action: "update_venue_subscription_status";
  venueId: string;
  newStatus: VenueSubscriptionStatus;
  status: "updated";
  auditEventId: string;
  replay?: boolean;
};

// -- Request/Response maps --

export type VenueCommandRequestMap = {
  create_venue: CreateVenueCommandRequest;
  update_venue_profile: UpdateVenueProfileCommandRequest;
  update_venue_visibility: UpdateVenueVisibilityCommandRequest;
  update_venue_operational_status: UpdateVenueOperationalStatusCommandRequest;
  update_venue_subscription_status: UpdateVenueSubscriptionStatusCommandRequest;
};

export type VenueCommandResponseMap = {
  create_venue: CreateVenueCommandResponse;
  update_venue_profile: UpdateVenueProfileCommandResponse;
  update_venue_visibility: UpdateVenueVisibilityCommandResponse;
  update_venue_operational_status: UpdateVenueOperationalStatusCommandResponse;
  update_venue_subscription_status: UpdateVenueSubscriptionStatusCommandResponse;
};

export type VenueCommandRequest = VenueCommandRequestMap[VenueCommandType];
export type VenueCommandResponse = VenueCommandResponseMap[VenueCommandType];

// -- Result types --

export type VenueCommandSuccess<T extends VenueCommandType> = {
  ok: true;
  command: T;
  commandId: string;
  correlationId: string;
  data: VenueCommandResponseMap[T];
};

export type VenueCommandFailure<T extends VenueCommandType> = {
  ok: false;
  command: T;
  commandId: string;
  correlationId: string;
  error: VenueCommandError;
};

export type VenueCommandResult<T extends VenueCommandType> =
  | VenueCommandSuccess<T>
  | VenueCommandFailure<T>;

// -- Idempotency --

export type VenueCommandIdempotencyExpectation = {
  required: true;
  keyField: "commandId";
  replayRule: "same_command_same_payload_returns_original";
};

// -- Expected state expectation --

export type VenueCommandExpectedStateExpectation = {
  required: boolean;
  requiredFields: readonly string[];
};

// -- Metadata --

export type VenueCommandMetadata = {
  requiredCapability: AdminCapabilityKey;
  allowedRoles: readonly AdminRole[];
  idempotency: VenueCommandIdempotencyExpectation;
  expectedState: VenueCommandExpectedStateExpectation;
};

const VENUE_ADMIN_ROLES: readonly AdminRole[] = ["super_admin"];
const VENUE_CONTENT_ROLES: readonly AdminRole[] = ["super_admin", "content_admin"];

const SHARED_IDEMPOTENCY: VenueCommandIdempotencyExpectation = {
  required: true,
  keyField: "commandId",
  replayRule: "same_command_same_payload_returns_original",
};

export const VENUE_COMMAND_METADATA: Record<VenueCommandType, VenueCommandMetadata> = {
  create_venue: {
    requiredCapability: "create_venue",
    allowedRoles: VENUE_ADMIN_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: false,
      requiredFields: [],
    },
  },
  update_venue_profile: {
    requiredCapability: "edit_venue_profile",
    allowedRoles: VENUE_CONTENT_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["operational_status"],
    },
  },
  update_venue_visibility: {
    requiredCapability: "change_venue_visibility",
    allowedRoles: VENUE_CONTENT_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["current_visibility", "operational_status"],
    },
  },
  update_venue_operational_status: {
    requiredCapability: "change_venue_operational_status",
    allowedRoles: VENUE_ADMIN_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["current_operational_status"],
    },
  },
  update_venue_subscription_status: {
    requiredCapability: "change_venue_subscription_status",
    allowedRoles: VENUE_ADMIN_ROLES,
    idempotency: SHARED_IDEMPOTENCY,
    expectedState: {
      required: true,
      requiredFields: ["current_subscription_status"],
    },
  },
};
