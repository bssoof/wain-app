import {
  mapBackendErrorToTransportError,
  type FinanceCallableInvoker,
} from "@/lib/finance/finance-command-transport";

import type {
  VenueCommandRequest,
  VenueCommandResponse,
  VenueCommandType,
} from "./venue-command-contracts";

export type VenueCommandTransportSuccess = {
  ok: true;
  data: VenueCommandResponse;
  correlationId?: string;
};

export type VenueCommandTransportFailure = {
  ok: false;
  error: unknown;
  correlationId?: string;
};

export type VenueCommandTransportResult =
  | VenueCommandTransportSuccess
  | VenueCommandTransportFailure;

export interface VenueManagementTransport {
  execute(
    command: VenueCommandRequest,
  ): Promise<VenueCommandTransportResult>;
}

export const VENUE_CALLABLE_SURFACES: Record<VenueCommandType, string> = {
  create_venue: "adminCreateVenue",
  update_venue_profile: "adminUpdateVenueProfile",
  update_venue_visibility: "adminUpdateVenueVisibility",
  update_venue_operational_status: "adminUpdateVenueOperationalStatus",
  update_venue_subscription_status: "adminUpdateVenueSubscriptionStatus",
};

export function createVenueAdaptersTransport(options: {
  invokeCallable: FinanceCallableInvoker;
}): VenueManagementTransport {
  return {
    async execute(
      command: VenueCommandRequest,
    ): Promise<VenueCommandTransportResult> {
      const callableName = VENUE_CALLABLE_SURFACES[command.action];
      try {
        const payload = buildCallablePayload(command);
        const response = asRecord(
          await options.invokeCallable(callableName, payload),
        );

        return {
          ok: true,
          correlationId: command.correlationId,
          data: {
            action: command.action,
            venueId: toNonEmptyString(response?.venueId) ?? toNonEmptyString(response?.venue_id) ?? "",
            status: normalizeOutcomeStatus(response?.status),
            auditEventId:
              toNonEmptyString(response?.auditEventId) ??
              toNonEmptyString(response?.audit_event_id) ??
              `${command.commandId}:${command.action}`,
            replay: response?.replay === true,
            ...extractStatusFields(command.action, response),
          } as VenueCommandResponse,
        };
      } catch (error) {
        return {
          ok: false,
          correlationId: command.correlationId,
          error: mapBackendErrorToTransportError(error),
        };
      }
    },
  };
}

function buildCallablePayload(command: VenueCommandRequest): Record<string, unknown> {
  const base: Record<string, unknown> = {
    action: command.action,
    commandId: command.commandId,
    correlationId: command.correlationId,
    idempotencyKey: command.commandId,
    submittedAt: command.submittedAt,
    reason: command.reason,
  };

  switch (command.action) {
    case "create_venue":
      return {
        ...base,
        nameAr: command.nameAr,
        city: command.city,
        categories: command.categories,
        nameEn: command.nameEn,
        phone: command.phone,
        instagram: command.instagram,
        whatsapp: command.whatsapp,
        facebook: command.facebook,
        website: command.website,
        minPrice: command.minPrice,
        maxPrice: command.maxPrice,
        currency: command.currency,
        photos: command.photos,
        menuImages: command.menuImages,
        hours: command.hours,
        is24h: command.is24h,
        tags: command.tags,
        transportEnabled: command.transportEnabled,
        transportPartnerIds: command.transportPartnerIds,
        transportNotesAr: command.transportNotesAr,
        transportNotesEn: command.transportNotesEn,
        lat: command.lat,
        lng: command.lng,
      };
    case "update_venue_profile":
      return {
        ...base,
        venueId: command.venueId,
        updates: command.updates,
        expectedState: command.expectedState,
      };
    case "update_venue_visibility":
      return {
        ...base,
        venueId: command.venueId,
        newVisibility: command.newVisibility,
        expectedState: command.expectedState,
      };
    case "update_venue_operational_status":
      return {
        ...base,
        venueId: command.venueId,
        newStatus: command.newStatus,
        expectedState: command.expectedState,
      };
    case "update_venue_subscription_status":
      return {
        ...base,
        venueId: command.venueId,
        newStatus: command.newStatus,
        expectedState: command.expectedState,
      };
  }
}

function extractStatusFields(
  action: VenueCommandType,
  response: Record<string, any> | undefined,
): Record<string, unknown> {
  if (!response) return {};
  switch (action) {
    case "update_venue_visibility":
      return {
        newVisibility: response.newVisibility ?? response.new_visibility ?? "visible",
      };
    case "update_venue_operational_status":
      return {
        newStatus: response.newStatus ?? response.new_status ?? "active",
      };
    case "update_venue_subscription_status":
      return {
        newStatus: response.newStatus ?? response.new_status ?? "active",
      };
    default:
      return {};
  }
}

function asRecord(value: unknown): Record<string, any> | undefined {
  if (!value || typeof value !== "object") {
    return undefined;
  }
  return value as Record<string, any>;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function normalizeOutcomeStatus(value: unknown): "created" | "updated" {
  if (value === "created") return "created";
  return "updated";
}
