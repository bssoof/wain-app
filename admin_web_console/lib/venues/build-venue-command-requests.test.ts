import { describe, expect, it } from "vitest";

import {
  buildCreateVenueRequest,
  buildUpdateVenueProfileRequest,
} from "./build-venue-command-requests";

describe("buildVenueCommandRequests", () => {
  it("includes required coordinates and extended profile fields in create_venue request", () => {
    const request = buildCreateVenueRequest({
      nameAr: "قهوة الاختبار",
      nameEn: "Test Cafe",
      city: "Ramallah",
      phone: "0599000000",
      categories: ["cafe"],
      instagram: "https://instagram.com/test",
      whatsapp: "+970599000000",
      facebook: "https://facebook.com/test",
      website: "https://example.com",
      minPrice: 20,
      maxPrice: 80,
      currency: "ILS",
      photos: ["https://cdn.example.com/photo.jpg"],
      menuImages: ["https://cdn.example.com/menu.jpg"],
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
      transportNotesAr: "متاح داخل المدينة",
      transportNotesEn: "City only",
      lat: 31.9516,
      lng: 35.9239,
      reason: "geo_parity",
    });

    expect(request.action).toBe("create_venue");
    expect(request.lat).toBe(31.9516);
    expect(request.lng).toBe(35.9239);
    expect(request.instagram).toBe("https://instagram.com/test");
    expect(request.currency).toBe("ILS");
    expect(request.tags?.timeOfDay).toEqual(["morning"]);
    expect(request.transportPartnerIds).toEqual(["partner_1"]);
    expect(request.commandId.length).toBeGreaterThan(0);
    expect(request.correlationId.length).toBeGreaterThan(0);
  });

  it("includes coordinate updates in update_venue_profile envelope", () => {
    const request = buildUpdateVenueProfileRequest({
      venueId: "venue_1",
      updates: {
        lat: 31.952,
        lng: 35.925,
        photos: ["https://cdn.example.com/venues/1.jpg"],
        menuImages: ["https://cdn.example.com/menus/1.jpg"],
      },
      reason: "move_pin",
      currentOperationalStatus: "active",
    });

    expect(request.action).toBe("update_venue_profile");
    expect(request.expectedState).toEqual({ operational_status: "active" });
    expect(request.updates.lat).toBe(31.952);
    expect(request.updates.lng).toBe(35.925);
    expect(request.updates.photos).toEqual(["https://cdn.example.com/venues/1.jpg"]);
    expect(request.updates.menuImages).toEqual(["https://cdn.example.com/menus/1.jpg"]);
  });
});
