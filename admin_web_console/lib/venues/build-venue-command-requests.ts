import type {
  CreateVenueCommandRequest,
  UpdateVenueProfileCommandRequest,
  UpdateVenueVisibilityCommandRequest,
  UpdateVenueOperationalStatusCommandRequest,
  UpdateVenueSubscriptionStatusCommandRequest,
  VenueCommandRequest,
} from "./venue-command-contracts";

function newIds(): { commandId: string; correlationId: string } {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return { commandId: crypto.randomUUID(), correlationId: crypto.randomUUID() };
  }
  const fallback = `venue-cmd-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  return { commandId: fallback, correlationId: `${fallback}_corr` };
}

export function buildCreateVenueRequest(input: {
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
  currency?: CreateVenueCommandRequest["currency"];
  photos?: string[];
  menuImages?: string[];
  hours?: CreateVenueCommandRequest["hours"];
  is24h?: boolean;
  tags?: CreateVenueCommandRequest["tags"];
  transportEnabled?: boolean;
  transportPartnerIds?: string[];
  transportNotesAr?: string;
  transportNotesEn?: string;
  reason: string;
}): CreateVenueCommandRequest {
  const { commandId, correlationId } = newIds();
  return {
    action: "create_venue",
    commandId,
    correlationId,
    submittedAt: new Date().toISOString(),
    nameAr: input.nameAr,
    city: input.city,
    categories: input.categories,
    nameEn: input.nameEn,
    phone: input.phone,
    instagram: input.instagram,
    whatsapp: input.whatsapp,
    facebook: input.facebook,
    website: input.website,
    minPrice: input.minPrice,
    maxPrice: input.maxPrice,
    currency: input.currency,
    photos: input.photos,
    menuImages: input.menuImages,
    hours: input.hours,
    is24h: input.is24h,
    tags: input.tags,
    transportEnabled: input.transportEnabled,
    transportPartnerIds: input.transportPartnerIds,
    transportNotesAr: input.transportNotesAr,
    transportNotesEn: input.transportNotesEn,
    lat: input.lat,
    lng: input.lng,
    reason: input.reason,
  };
}

export function buildUpdateVenueProfileRequest(input: {
  venueId: string;
  updates: UpdateVenueProfileCommandRequest["updates"];
  reason: string;
  currentOperationalStatus: "active";
}): UpdateVenueProfileCommandRequest {
  const { commandId, correlationId } = newIds();
  return {
    action: "update_venue_profile",
    commandId,
    correlationId,
    submittedAt: new Date().toISOString(),
    venueId: input.venueId,
    updates: input.updates,
    reason: input.reason,
    expectedState: {
      operational_status: input.currentOperationalStatus,
    },
  };
}

export function buildUpdateVenueVisibilityRequest(input: {
  venueId: string;
  newVisibility: "visible" | "hidden";
  currentVisibility: "visible" | "hidden";
  currentOperationalStatus: "active" | "suspended" | "archived";
  reason: string;
}): UpdateVenueVisibilityCommandRequest {
  const { commandId, correlationId } = newIds();
  return {
    action: "update_venue_visibility",
    commandId,
    correlationId,
    submittedAt: new Date().toISOString(),
    venueId: input.venueId,
    newVisibility: input.newVisibility,
    reason: input.reason,
    expectedState: {
      current_visibility: input.currentVisibility,
      operational_status: input.currentOperationalStatus,
    },
  };
}

export function buildUpdateVenueOperationalStatusRequest(input: {
  venueId: string;
  newStatus: "active" | "suspended" | "archived";
  currentStatus: "active" | "suspended" | "archived";
  reason: string;
}): UpdateVenueOperationalStatusCommandRequest {
  const { commandId, correlationId } = newIds();
  return {
    action: "update_venue_operational_status",
    commandId,
    correlationId,
    submittedAt: new Date().toISOString(),
    venueId: input.venueId,
    newStatus: input.newStatus,
    reason: input.reason,
    expectedState: {
      current_operational_status: input.currentStatus,
    },
  };
}

export function buildUpdateVenueSubscriptionStatusRequest(input: {
  venueId: string;
  newStatus: "active" | "expired" | "paused";
  currentStatus: "active" | "expired" | "paused";
  reason: string;
}): UpdateVenueSubscriptionStatusCommandRequest {
  const { commandId, correlationId } = newIds();
  return {
    action: "update_venue_subscription_status",
    commandId,
    correlationId,
    submittedAt: new Date().toISOString(),
    venueId: input.venueId,
    newStatus: input.newStatus,
    reason: input.reason,
    expectedState: {
      current_subscription_status: input.currentStatus,
    },
  };
}

/** Type guard to narrow a generic request to a specific command type. */
export function isVenueCommand<A extends VenueCommandRequest["action"]>(
  request: VenueCommandRequest,
  action: A,
): request is Extract<VenueCommandRequest, { action: A }> {
  return request.action === action;
}
