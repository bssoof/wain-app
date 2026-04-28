import { describe, expect, it, vi } from "vitest";

import {
  createVenueAdaptersTransport,
  VENUE_CALLABLE_SURFACES,
} from "./venue-command-adapters";
import type {
  CreateVenueCommandRequest,
  UpdateVenueProfileCommandRequest,
} from "./venue-command-contracts";
import {
  createTypeSafeMockInvoker,
  readCallableMockCall,
} from "../testing/type-safe-mock-invoker";

function createVenueRequest(): CreateVenueCommandRequest {
  return {
    action: "create_venue",
    commandId: "cmd_create_geo_1",
    correlationId: "corr_create_geo_1",
    reason: "geo_create",
    submittedAt: "2026-04-12T10:00:00.000Z",
    nameAr: "قهوة جيو",
    nameEn: "Geo Cafe",
    city: "Ramallah",
    phone: "0599000000",
    instagram: "https://instagram.com/geo-cafe",
    whatsapp: "+970599000000",
    facebook: "https://facebook.com/geo-cafe",
    website: "https://geo-cafe.example",
    minPrice: 25,
    maxPrice: 85,
    currency: "ILS",
    photos: ["https://cdn.example.com/photo-1.jpg"],
    menuImages: ["https://cdn.example.com/menu-1.jpg"],
    hours: {
      monday: [{ open: "09:00", close: "22:00" }],
    },
    is24h: false,
    tags: {
      mood: ["cozy"],
      occasion: ["family"],
      timeOfDay: ["morning"],
      meal: ["breakfast"],
    },
    transportEnabled: true,
    transportPartnerIds: ["partner_1"],
    transportNotesAr: "داخل المدينة",
    transportNotesEn: "Within city",
    categories: ["cafe"],
    lat: 31.9516,
    lng: 35.9239,
  };
}

function updateVenueProfileRequest(): UpdateVenueProfileCommandRequest {
  return {
    action: "update_venue_profile",
    commandId: "cmd_update_geo_1",
    correlationId: "corr_update_geo_1",
    reason: "geo_update",
    submittedAt: "2026-04-12T10:01:00.000Z",
    venueId: "venue_1",
    expectedState: {
      operational_status: "active",
    },
    updates: {
      lat: 31.952,
      lng: 35.925,
      photos: ["https://cdn.example.com/photo-2.jpg"],
      menuImages: ["https://cdn.example.com/menu-2.jpg"],
    },
  };
}

describe("venue command adapters", () => {
  it("maps create_venue payload with extended fields to callable", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      venueId: "venue_1",
      status: "created",
      auditEventId: "audit_1",
    }));
    const transport = createVenueAdaptersTransport({ invokeCallable });
    const request = createVenueRequest();

    const result = await transport.execute(request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);
    expect(callableName).toBe(VENUE_CALLABLE_SURFACES.create_venue);
    expect(payload.lat).toBe(31.9516);
    expect(payload.lng).toBe(35.9239);
    expect(payload.instagram).toBe("https://instagram.com/geo-cafe");
    expect(payload.currency).toBe("ILS");
    expect(payload.tags).toEqual({
      mood: ["cozy"],
      occasion: ["family"],
      timeOfDay: ["morning"],
      meal: ["breakfast"],
    });
    expect(payload.transportEnabled).toBe(true);
    expect(payload.commandId).toBe("cmd_create_geo_1");
    expect(result.ok).toBe(true);
  });

  it("passes lat/lng profile updates to update_venue_profile callable", async () => {
    const invokeCallable = createTypeSafeMockInvoker(async () => ({
      venueId: "venue_1",
      status: "updated",
      auditEventId: "audit_profile_1",
    }));
    const transport = createVenueAdaptersTransport({ invokeCallable });
    const request = updateVenueProfileRequest();

    const result = await transport.execute(request);

    expect(invokeCallable).toHaveBeenCalledTimes(1);
    const [callableName, payload] = readCallableMockCall(invokeCallable);
    expect(callableName).toBe(VENUE_CALLABLE_SURFACES.update_venue_profile);
    expect(payload.venueId).toBe("venue_1");
    expect(payload.updates).toEqual({
      lat: 31.952,
      lng: 35.925,
      photos: ["https://cdn.example.com/photo-2.jpg"],
      menuImages: ["https://cdn.example.com/menu-2.jpg"],
    });
    expect(result.ok).toBe(true);
  });
});
