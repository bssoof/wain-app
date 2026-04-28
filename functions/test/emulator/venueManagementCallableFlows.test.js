const test = require("node:test");
const assert = require("node:assert/strict");

process.env.GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "demo-wain-venue";
process.env.FIRESTORE_EMULATOR_HOST =
  process.env.FIRESTORE_EMULATOR_HOST || "127.0.0.1:8080";

const admin = require("firebase-admin");
const {
  adminCreateVenue,
  adminUpdateVenueProfile,
  adminUpdateVenueVisibility,
  adminUpdateVenueOperationalStatus,
  adminUpdateVenueSubscriptionStatus,
  listVenuesForAdmin,
  searchVenuesInBounds,
} = require("../../lib/index.js");

const db = admin.firestore();
const projectId = process.env.GCLOUD_PROJECT;
const emulatorHost = process.env.FIRESTORE_EMULATOR_HOST;

async function clearFirestore() {
  const url =
    `http://${emulatorHost}/emulator/v1/projects/` +
    `${projectId}/databases/(default)/documents`;
  const res = await fetch(url, { method: "DELETE" });
  if (!res.ok) {
    throw new Error(`Failed to clear Firestore emulator: ${res.status}`);
  }
}

function callableContext({ uid, role, appCheck = true, ownerHeader = false } = {}) {
  const token = { admin: true };
  if (role === "super_admin") {
    token.role = "super_admin";
    token.super_admin = true;
  } else if (role === "content_admin") {
    token.role = "content_admin";
    token.content_admin = true;
  } else if (role === "finance_admin") {
    token.role = "finance_admin";
    token.finance_admin = true;
  }

  return {
    auth: uid ? { uid, token } : null,
    app: appCheck ? { appId: "venue-emulator" } : undefined,
    rawRequest: ownerHeader
      ? {
          headers: {
            authorization: "Bearer owner",
          },
        }
      : undefined,
  };
}

async function expectHttpsError(action, expectedCodeOrMessage) {
  let error = null;
  try {
    await action();
  } catch (err) {
    error = err;
  }

  assert.ok(error, `Expected callable to throw ${expectedCodeOrMessage}`);
  assert.ok(
    error.code === expectedCodeOrMessage ||
      String(error.message || "").includes(expectedCodeOrMessage),
    `Expected "${expectedCodeOrMessage}", got code "${error.code}" and message "${error.message}"`,
  );
  return error;
}

async function seedVenue(venueId, overrides = {}) {
  const now = admin.firestore.Timestamp.now();
  await db.collection("venues").doc(venueId).set(
    {
      name_ar: "مقهى الاختبار",
      name_en: "",
      name: "مقهى الاختبار",
      name_ar_norm: "مقهى الاختبار",
      name_en_norm: "",
      lat: 0,
      lng: 0,
      city: "رام الله",
      categories: ["cafe"],
      tags: {
        mood: [],
        occasion: [],
        time_of_day: [],
        meal: [],
      },
      all_tags: [],
      min_price: 0,
      max_price: 0,
      currency: "ILS",
      rating: 0,
      phone: "0599000000",
      instagram: "",
      whatsapp: "",
      facebook: "",
      website: "",
      photos: [],
      menu_images: [],
      hours: {},
      is_24h: false,
      partner: {
        is_partner: false,
        tier: "C",
      },
      has_active_offers: false,
      transport_enabled: false,
      transport_partner_ids: [],
      transport_notes_ar: "",
      transport_notes_en: "",
      is_active: true,
      subscription_status: "active",
      visibility_status: "visible",
      operational_status: "active",
      admin_status_updated_at: now,
      admin_status_updated_by: "seed",
      created_at: now,
      updated_at: now,
      ...overrides,
    },
    { merge: true },
  );
}

test("Venue Management Callables", async (t) => {
  if (process.env.SKIP_EMULATOR_TESTS === "true") {
    return;
  }

  t.beforeEach(async () => {
    await clearFirestore();
  });

  t.afterEach(async () => {
    await clearFirestore();
  });

  await t.test("VM01 - super admin can create a venue with governed defaults", async () => {
    const result = await adminCreateVenue.run(
      {
        action: "create_venue",
        commandId: "cmd_vm_create_001",
        correlationId: "corr_vm_create_001",
        reason: "initial_onboarding",
        submittedAt: "2026-04-12T10:00:00.000Z",
        nameAr: "قهوة البلد",
        city: "رام الله",
        categories: ["cafe", "breakfast"],
        lat: 31.9516,
        lng: 35.9239,
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    assert.equal(result.action, "create_venue");
    assert.equal(result.status, "created");
    assert.equal(result.replay, false);
    assert.ok(result.venueId);

    const venueDoc = await db.collection("venues").doc(result.venueId).get();
    const venue = venueDoc.data();
    assert.equal(venue.name_ar, "قهوة البلد");
    assert.equal(venue.name_en, "");
    assert.equal(venue.city, "رام الله");
    assert.deepEqual(venue.categories, ["cafe", "breakfast"]);
    assert.equal(venue.phone, "");
    assert.equal(venue.lat, 31.9516);
    assert.equal(venue.lng, 35.9239);
    assert.equal(venue.subscription_status, "active");
    assert.equal(venue.visibility_status, "visible");
    assert.equal(venue.operational_status, "active");
    assert.equal(venue.is_active, true);

    const auditSnap = await db
      .collection("venue_admin_events")
      .where("command_id", "==", "cmd_vm_create_001")
      .get();
    assert.equal(auditSnap.size, 1);
  });

  await t.test("VM01B - emulator owner header is treated as super admin for venue create", async () => {
    const previousEmulatorFlag = process.env.FUNCTIONS_EMULATOR;
    process.env.FUNCTIONS_EMULATOR = "true";

    try {
      const result = await adminCreateVenue.run(
        {
          action: "create_venue",
          commandId: "cmd_vm_create_001b",
          correlationId: "corr_vm_create_001b",
          reason: "local_parity_owner_flow",
          submittedAt: "2026-04-12T10:00:30.000Z",
          nameAr: "owner parity venue",
          city: "ramallah",
          categories: ["cafe"],
          lat: 31.9512,
          lng: 35.9242,
        },
        callableContext({ uid: "owner", ownerHeader: true }),
      );

      assert.equal(result.action, "create_venue");
      assert.equal(result.status, "created");
      assert.ok(result.venueId);
    } finally {
      if (previousEmulatorFlag === undefined) {
        delete process.env.FUNCTIONS_EMULATOR;
      } else {
        process.env.FUNCTIONS_EMULATOR = previousEmulatorFlag;
      }
    }
  });

  await t.test("VM02 - replaying the same create command returns the stored result", async () => {
    const payload = {
      action: "create_venue",
      commandId: "cmd_vm_create_002",
      correlationId: "corr_vm_create_002",
      reason: "initial_onboarding",
      submittedAt: "2026-04-12T10:01:00.000Z",
      nameAr: "قهوة وسط البلد",
      city: "نابلس",
      categories: ["cafe"],
      lat: 32.222,
      lng: 35.255,
    };

    const first = await adminCreateVenue.run(
      payload,
      callableContext({ uid: "super_1", role: "super_admin" }),
    );
    const replay = await adminCreateVenue.run(
      payload,
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    assert.equal(first.replay, false);
    assert.equal(replay.replay, true);
    assert.equal(replay.venueId, first.venueId);

    const venueSnap = await db.collection("venues").get();
    assert.equal(venueSnap.size, 1);

    const commandSnap = await db.collection("venue_admin_commands").get();
    assert.equal(commandSnap.size, 1);
  });

  await t.test("VM03 - reusing a create command id with a different payload is rejected", async () => {
    const context = callableContext({ uid: "super_1", role: "super_admin" });
    await adminCreateVenue.run(
      {
        action: "create_venue",
        commandId: "cmd_vm_create_003",
        reason: "initial_onboarding",
        submittedAt: "2026-04-12T10:02:00.000Z",
        nameAr: "قهوة أولى",
        city: "الخليل",
        categories: ["cafe"],
        lat: 31.532,
        lng: 35.099,
      },
      context,
    );

    await expectHttpsError(
      () =>
        adminCreateVenue.run(
          {
            action: "create_venue",
            commandId: "cmd_vm_create_003",
            reason: "initial_onboarding",
            submittedAt: "2026-04-12T10:02:00.000Z",
            nameAr: "قهوة مختلفة",
            city: "الخليل",
            categories: ["cafe"],
            lat: 31.532,
            lng: 35.099,
          },
          context,
        ),
      "venue_command_payload_conflict",
    );
  });

  await t.test("VM04 - content admin can update the venue profile for an active venue", async () => {
    await seedVenue("venue_profile_1");

    const result = await adminUpdateVenueProfile.run(
      {
        action: "update_venue_profile",
        commandId: "cmd_vm_profile_001",
        reason: "ops_correction",
        venueId: "venue_profile_1",
        expectedState: {
          operational_status: "active",
        },
        updates: {
          nameAr: "قهوة محدثة",
          city: "بيت لحم",
          categories: ["cafe", "dessert"],
          phone: "0599111111",
          lat: 31.7054,
          lng: 35.2045,
        },
      },
      callableContext({ uid: "content_1", role: "content_admin" }),
    );

    assert.equal(result.status, "updated");
    assert.equal(result.replay, false);

    const venueDoc = await db.collection("venues").doc("venue_profile_1").get();
    const venue = venueDoc.data();
    assert.equal(venue.name_ar, "قهوة محدثة");
    assert.equal(venue.city, "بيت لحم");
    assert.equal(venue.phone, "0599111111");
    assert.deepEqual(venue.categories, ["cafe", "dessert"]);
    assert.equal(venue.lat, 31.7054);
    assert.equal(venue.lng, 35.2045);
  });

  await t.test("VM04B - content admin can update profile media arrays", async () => {
    await seedVenue("venue_profile_media_1", {
      photos: ["https://cdn.example.com/venues/old.jpg"],
      menu_images: ["https://cdn.example.com/menus/old.jpg"],
    });

    const result = await adminUpdateVenueProfile.run(
      {
        action: "update_venue_profile",
        commandId: "cmd_vm_profile_media_001",
        reason: "sync_uploaded_media",
        venueId: "venue_profile_media_1",
        expectedState: {
          operational_status: "active",
        },
        updates: {
          photos: ["https://cdn.example.com/venues/new-1.jpg"],
          menuImages: ["https://cdn.example.com/menus/new-1.jpg"],
        },
      },
      callableContext({ uid: "content_1", role: "content_admin" }),
    );

    assert.equal(result.status, "updated");

    const venueDoc = await db.collection("venues").doc("venue_profile_media_1").get();
    const venue = venueDoc.data();
    assert.deepEqual(venue.photos, ["https://cdn.example.com/venues/new-1.jpg"]);
    assert.deepEqual(venue.menu_images, ["https://cdn.example.com/menus/new-1.jpg"]);
  });

  await t.test("VM05 - finance admin cannot update venue profile", async () => {
    await seedVenue("venue_profile_2");

    await expectHttpsError(
      () =>
        adminUpdateVenueProfile.run(
          {
            action: "update_venue_profile",
            commandId: "cmd_vm_profile_002",
            reason: "ops_correction",
            venueId: "venue_profile_2",
            updates: {
              city: "القدس",
            },
          },
          callableContext({ uid: "finance_1", role: "finance_admin" }),
        ),
      "venue_role_not_authorized",
    );
  });

  await t.test("VM06 - content admin can hide a venue explicitly", async () => {
    await seedVenue("venue_visibility_1");

    const result = await adminUpdateVenueVisibility.run(
      {
        action: "update_venue_visibility",
        commandId: "cmd_vm_visibility_001",
        reason: "temporary_hide",
        venueId: "venue_visibility_1",
        newVisibility: "hidden",
        expectedState: {
          current_visibility: "visible",
          operational_status: "active",
        },
      },
      callableContext({ uid: "content_1", role: "content_admin" }),
    );

    assert.equal(result.newVisibility, "hidden");

    const venueDoc = await db.collection("venues").doc("venue_visibility_1").get();
    const venue = venueDoc.data();
    assert.equal(venue.visibility_status, "hidden");
    assert.equal(venue.is_active, false);
  });

  await t.test("VM07 - venue cannot become visible without a phone number", async () => {
    await seedVenue("venue_visibility_2", {
      phone: "",
      visibility_status: "hidden",
      is_active: false,
    });

    await expectHttpsError(
      () =>
        adminUpdateVenueVisibility.run(
          {
            action: "update_venue_visibility",
            commandId: "cmd_vm_visibility_002",
            reason: "re_enable_listing",
            venueId: "venue_visibility_2",
            newVisibility: "visible",
            expectedState: {
              current_visibility: "hidden",
              operational_status: "active",
            },
          },
          callableContext({ uid: "content_1", role: "content_admin" }),
        ),
      "venue_phone_required_for_visibility",
    );
  });

  await t.test("VM08 - venue visibility expected-state conflicts are rejected", async () => {
    await seedVenue("venue_visibility_3", {
      visibility_status: "hidden",
      is_active: false,
    });

    await expectHttpsError(
      () =>
        adminUpdateVenueVisibility.run(
          {
            action: "update_venue_visibility",
            commandId: "cmd_vm_visibility_003",
            reason: "operator_retry",
            venueId: "venue_visibility_3",
            newVisibility: "visible",
            expectedState: {
              current_visibility: "visible",
              operational_status: "active",
            },
          },
          callableContext({ uid: "content_1", role: "content_admin" }),
        ),
      "venue_expected_state_conflict",
    );
  });

  await t.test("VM09 - super admin can suspend a venue and force it hidden", async () => {
    await seedVenue("venue_operational_1", {
      visibility_status: "visible",
      subscription_status: "active",
      is_active: true,
    });

    const result = await adminUpdateVenueOperationalStatus.run(
      {
        action: "update_venue_operational_status",
        commandId: "cmd_vm_operational_001",
        reason: "ops_hold",
        venueId: "venue_operational_1",
        newStatus: "suspended",
        expectedState: {
          current_operational_status: "active",
        },
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    assert.equal(result.newStatus, "suspended");

    const venueDoc = await db.collection("venues").doc("venue_operational_1").get();
    const venue = venueDoc.data();
    assert.equal(venue.operational_status, "suspended");
    assert.equal(venue.visibility_status, "hidden");
    assert.equal(venue.is_active, false);
  });

  await t.test("VM10 - super admin can pause a venue subscription", async () => {
    await seedVenue("venue_subscription_1", {
      visibility_status: "visible",
      operational_status: "active",
      subscription_status: "active",
      is_active: true,
    });

    const result = await adminUpdateVenueSubscriptionStatus.run(
      {
        action: "update_venue_subscription_status",
        commandId: "cmd_vm_subscription_001",
        reason: "billing_pause",
        venueId: "venue_subscription_1",
        newStatus: "paused",
        expectedState: {
          current_subscription_status: "active",
        },
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    assert.equal(result.newStatus, "paused");

    const venueDoc = await db.collection("venues").doc("venue_subscription_1").get();
    const venue = venueDoc.data();
    assert.equal(venue.subscription_status, "paused");
    assert.equal(venue.is_active, false);
  });

  await t.test("VM11 - content admin cannot change operational status", async () => {
    await seedVenue("venue_operational_2");

    await expectHttpsError(
      () =>
        adminUpdateVenueOperationalStatus.run(
          {
            action: "update_venue_operational_status",
            commandId: "cmd_vm_operational_002",
            reason: "ops_hold",
            venueId: "venue_operational_2",
            newStatus: "suspended",
          },
          callableContext({ uid: "content_1", role: "content_admin" }),
        ),
      "venue_role_not_authorized",
    );
  });

  await t.test("VM12 - app check is required for venue create", async () => {
    await expectHttpsError(
      () =>
        adminCreateVenue.run(
          {
            action: "create_venue",
            commandId: "cmd_vm_create_004",
            reason: "initial_onboarding",
            submittedAt: "2026-04-12T10:03:00.000Z",
            nameAr: "قهوة بدون تحقق",
            city: "رام الله",
            categories: ["cafe"],
            lat: 31.9516,
            lng: 35.9239,
          },
          callableContext({ uid: "super_1", role: "super_admin", appCheck: false }),
        ),
      "App Check verification failed",
    );
  });

  await t.test("VM13 - expected state is required for profile updates", async () => {
    await seedVenue("venue_profile_3");

    await expectHttpsError(
      () =>
        adminUpdateVenueProfile.run(
          {
            action: "update_venue_profile",
            commandId: "cmd_vm_profile_003",
            reason: "ops_correction",
            venueId: "venue_profile_3",
            updates: {
              city: "جنين",
            },
          },
          callableContext({ uid: "content_1", role: "content_admin" }),
        ),
      "venue_expected_state_required",
    );
  });

  await t.test("VM14 - invalid visibility status is rejected", async () => {
    await seedVenue("venue_visibility_4", {
      visibility_status: "visible",
      operational_status: "active",
      subscription_status: "active",
    });

    await expectHttpsError(
      () =>
        adminUpdateVenueVisibility.run(
          {
            action: "update_venue_visibility",
            commandId: "cmd_vm_visibility_004",
            reason: "invalid_transition",
            venueId: "venue_visibility_4",
            newVisibility: "paused",
            expectedState: {
              current_visibility: "visible",
              operational_status: "active",
            },
          },
          callableContext({ uid: "content_1", role: "content_admin" }),
        ),
      "invalid_venue_visibility_status",
    );
  });

  await t.test("VM15 - invalid operational status is rejected", async () => {
    await seedVenue("venue_operational_3", {
      operational_status: "active",
    });

    await expectHttpsError(
      () =>
        adminUpdateVenueOperationalStatus.run(
          {
            action: "update_venue_operational_status",
            commandId: "cmd_vm_operational_003",
            reason: "invalid_transition",
            venueId: "venue_operational_3",
            newStatus: "inactive",
            expectedState: {
              current_operational_status: "active",
            },
          },
          callableContext({ uid: "super_1", role: "super_admin" }),
        ),
      "invalid_venue_operational_status",
    );
  });

  await t.test("VM16 - invalid subscription status is rejected", async () => {
    await seedVenue("venue_subscription_2", {
      subscription_status: "active",
      operational_status: "active",
      visibility_status: "visible",
    });

    await expectHttpsError(
      () =>
        adminUpdateVenueSubscriptionStatus.run(
          {
            action: "update_venue_subscription_status",
            commandId: "cmd_vm_subscription_002",
            reason: "invalid_transition",
            venueId: "venue_subscription_2",
            newStatus: "disabled",
            expectedState: {
              current_subscription_status: "active",
            },
          },
          callableContext({ uid: "super_1", role: "super_admin" }),
        ),
      "invalid_venue_subscription_status",
    );
  });

  await t.test("VM17 - admin venue list includes created venue with stored coordinates", async () => {
    const createResult = await adminCreateVenue.run(
      {
        action: "create_venue",
        commandId: "cmd_vm_list_001",
        correlationId: "corr_vm_list_001",
        reason: "admin_directory_linkage",
        submittedAt: "2026-04-12T10:05:00.000Z",
        nameAr: "جهة من الأدمن",
        city: "رام الله",
        categories: ["cafe"],
        lat: 31.9509,
        lng: 35.9241,
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    const listResult = await listVenuesForAdmin.run(
      {
        limit: 50,
        correlationId: "corr_vm_list_001",
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    assert.ok(Array.isArray(listResult.items));
    const createdVenue = listResult.items.find((item) => item.id === createResult.venueId);
    assert.ok(createdVenue, "Expected created venue to appear in admin list read.");
    assert.equal(createdVenue.name_ar, "جهة من الأدمن");
    assert.equal(createdVenue.city, "رام الله");
    assert.equal(createdVenue.subscription_status, "active");
    assert.equal(createdVenue.visibility_status, "visible");
    assert.equal(createdVenue.operational_status, "active");
    assert.equal(createdVenue.lat, 31.9509);
    assert.equal(createdVenue.lng, 35.9241);
  });

  await t.test("VM18 - finance admin can read the governed venue list", async () => {
    await seedVenue("venue_list_finance_1", {
      name_ar: "قراءة مالية للجهات",
      city: "نابلس",
      categories: ["restaurant"],
    });

    const listResult = await listVenuesForAdmin.run(
      {
        limit: 20,
        correlationId: "corr_vm_list_002",
      },
      callableContext({ uid: "finance_1", role: "finance_admin" }),
    );

    assert.ok(Array.isArray(listResult.items));
    const seededVenue = listResult.items.find((item) => item.id === "venue_list_finance_1");
    assert.ok(seededVenue, "Expected finance admin venue list to include seeded venue.");
    assert.equal(seededVenue.name_ar, "قراءة مالية للجهات");
  });

  await t.test("VM19 - app check is required for admin venue list reads", async () => {
    await seedVenue("venue_list_appcheck_1");

    await expectHttpsError(
      () =>
        listVenuesForAdmin.run(
          {
            limit: 20,
            correlationId: "corr_vm_list_003",
          },
          callableContext({ uid: "super_1", role: "super_admin", appCheck: false }),
        ),
      "App Check verification failed",
    );
  });

  await t.test("VM20 - missing venue coordinates are rejected on create", async () => {
    await expectHttpsError(
      () =>
        adminCreateVenue.run(
          {
            action: "create_venue",
            commandId: "cmd_vm_create_missing_coords_001",
            correlationId: "corr_vm_create_missing_coords_001",
            reason: "missing_latlng_check",
            submittedAt: "2026-04-12T10:06:00.000Z",
            nameAr: "قهوة بدون إحداثيات",
            city: "رام الله",
            categories: ["cafe"],
          },
          callableContext({ uid: "super_1", role: "super_admin" }),
        ),
      "invalid_venue_coordinates",
    );
  });

  await t.test("VM21 - invalid venue coordinates are rejected on create", async () => {
    await expectHttpsError(
      () =>
        adminCreateVenue.run(
          {
            action: "create_venue",
            commandId: "cmd_vm_create_invalid_coords_001",
            correlationId: "corr_vm_create_invalid_coords_001",
            reason: "invalid_latlng_check",
            submittedAt: "2026-04-12T10:06:00.000Z",
            nameAr: "قهوة بإحداثيات غير صالحة",
            city: "رام الله",
            categories: ["cafe"],
            lat: 95,
            lng: 35.9,
          },
          callableContext({ uid: "super_1", role: "super_admin" }),
        ),
      "invalid_venue_coordinates",
    );
  });

  await t.test("VM22 - created venue with coordinates is discoverable in app bounds search", async () => {
    const createResult = await adminCreateVenue.run(
      {
        action: "create_venue",
        commandId: "cmd_vm_geo_search_001",
        correlationId: "corr_vm_geo_search_001",
        reason: "geo_discoverability_check",
        submittedAt: "2026-04-12T10:07:00.000Z",
        nameAr: "جهة قابلة للاكتشاف",
        city: "رام الله",
        categories: ["cafe"],
        lat: 31.9525,
        lng: 35.9253,
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    const searchResult = await searchVenuesInBounds.run(
      {
        minLat: 31.94,
        maxLat: 31.96,
        minLng: 35.92,
        maxLng: 35.94,
        limit: 50,
        deviceId: "vm21_geo_search",
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    assert.ok(Array.isArray(searchResult.venues));
    assert.ok(
      searchResult.venues.some((venue) => venue.id === createResult.venueId),
      "Expected created venue to be returned by searchVenuesInBounds.",
    );
  });

  await t.test("VM23 - super admin can create a venue with extended profile fields", async () => {
    const result = await adminCreateVenue.run(
      {
        action: "create_venue",
        commandId: "cmd_vm_create_full_001",
        correlationId: "corr_vm_create_full_001",
        reason: "full_profile_onboarding",
        submittedAt: "2026-04-12T10:08:00.000Z",
        nameAr: "قهوة كاملة",
        nameEn: "Full Cafe",
        city: "رام الله",
        phone: "0599888777",
        categories: ["cafe", "breakfast"],
        lat: 31.9521,
        lng: 35.9244,
        instagram: "https://instagram.com/full_cafe",
        whatsapp: "+970599888777",
        facebook: "https://facebook.com/full_cafe",
        website: "https://full-cafe.example",
        minPrice: 25,
        maxPrice: 95,
        currency: "USD",
        photos: ["https://cdn.example.com/venues/full-1.jpg"],
        menuImages: ["https://cdn.example.com/menus/full-1.jpg"],
        hours: {
          monday: [{ open: "09:00", close: "22:00" }],
        },
        tags: {
          mood: ["cozy"],
          occasion: ["family"],
          timeOfDay: ["morning"],
          meal: ["breakfast"],
        },
        transportEnabled: true,
        transportPartnerIds: ["partner_1", "partner_2"],
        transportNotesAr: "متاح داخل المدينة",
        transportNotesEn: "Available within city",
      },
      callableContext({ uid: "super_1", role: "super_admin" }),
    );

    const venueDoc = await db.collection("venues").doc(result.venueId).get();
    const venue = venueDoc.data();

    assert.equal(venue.instagram, "https://instagram.com/full_cafe");
    assert.equal(venue.currency, "USD");
    assert.equal(venue.min_price, 25);
    assert.equal(venue.max_price, 95);
    assert.deepEqual(venue.photos, ["https://cdn.example.com/venues/full-1.jpg"]);
    assert.deepEqual(venue.menu_images, ["https://cdn.example.com/menus/full-1.jpg"]);
    assert.equal(venue.is_24h, false);
    assert.deepEqual(venue.hours, {
      monday: [{ open: "09:00", close: "22:00", spans_midnight: false }],
    });
    assert.deepEqual(venue.tags.time_of_day, ["morning"]);
    assert.ok(venue.all_tags.includes("cozy"));
    assert.ok(venue.all_tags.includes("morning"));
    assert.equal(venue.transport_enabled, true);
    assert.deepEqual(venue.transport_partner_ids, ["partner_1", "partner_2"]);
    assert.equal(venue.transport_notes_ar, "متاح داخل المدينة");
  });

  await t.test("VM24 - invalid create price range is rejected", async () => {
    await expectHttpsError(
      () =>
        adminCreateVenue.run(
          {
            action: "create_venue",
            commandId: "cmd_vm_create_invalid_price_001",
            correlationId: "corr_vm_create_invalid_price_001",
            reason: "invalid_price_range",
            submittedAt: "2026-04-12T10:09:00.000Z",
            nameAr: "قهوة بسعر غير صالح",
            city: "رام الله",
            categories: ["cafe"],
            lat: 31.95,
            lng: 35.92,
            minPrice: 150,
            maxPrice: 50,
          },
          callableContext({ uid: "super_1", role: "super_admin" }),
        ),
      "invalid_venue_price_range",
    );
  });

  await t.test("VM25 - invalid create hours payload is rejected", async () => {
    await expectHttpsError(
      () =>
        adminCreateVenue.run(
          {
            action: "create_venue",
            commandId: "cmd_vm_create_invalid_hours_001",
            correlationId: "corr_vm_create_invalid_hours_001",
            reason: "invalid_hours_payload",
            submittedAt: "2026-04-12T10:09:30.000Z",
            nameAr: "قهوة بمواعيد غير صالحة",
            city: "رام الله",
            categories: ["cafe"],
            lat: 31.95,
            lng: 35.92,
            hours: {
              monday: [{ open: "25:00", close: "10:00" }],
            },
          },
          callableContext({ uid: "super_1", role: "super_admin" }),
        ),
      "invalid_venue_hours",
    );
  });
});
