/**
 * VENUE-PARITY-01A — Local environment alignment and parity verification
 *
 * This script creates a venue via the admin callable, then verifies it appears
 * in both the admin list (listVenuesForAdmin) and the app read path
 * (searchVenuesInBounds) — all against the same local Firebase emulator.
 */

async function checkParity() {
  console.log("=== VENUE-PARITY-01A: Local Environment Parity Check ===\n");

  const projectId = "wain-d2e28";
  const baseUrl = `http://127.0.0.1:5001/${projectId}/us-central1`;
  const fsHost = "http://127.0.0.1:8080";
  const uniqueId = Date.now();
  const commandId = `cmd-parity-${uniqueId}`;

  const HEADERS_ADMIN = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer owner',
    'X-Firebase-AppCheck': 'local-dev-app-check',
  };

  // ── Step 1: Create venue from admin callable path ──
  console.log(`Step 1: Creating venue via adminCreateVenue (commandId: ${commandId})`);
  const createRes = await fetch(`${baseUrl}/adminCreateVenue`, {
    method: 'POST',
    headers: HEADERS_ADMIN,
    body: JSON.stringify({
      data: {
        nameAr: "مقهى باريتي للتحقق",
        nameEn: "Parity Check Cafe",
        city: "رام الله",
        categories: ["cafe"],
        lat: 31.9,
        lng: 35.2,
        phone: "0599000001",
        commandId,
        correlationId: "parity-e2e",
        reason: "Parity verification test",
      }
    })
  });
  const createBody = await createRes.json();
  console.log("  HTTP Status:", createRes.status);
  console.log("  Response:", JSON.stringify(createBody, null, 2));

  const createdVenueId = createBody?.result?.data?.venueId
    ?? createBody?.result?.venueId
    ?? createBody?.data?.venueId
    ?? null;

  if (!createdVenueId && createRes.status !== 200) {
    console.log("\n❌ STEP 1 FAILED — venue not created. Aborting.");
    console.log("  Blocker: adminCreateVenue returned non-200 or missing venueId");
    return;
  }

  console.log("  Created venueId:", createdVenueId || "(check response structure)");

  // ── Step 2: Confirm venue exists in raw Firestore emulator ──
  console.log("\nStep 2: Checking raw Firestore for venue document...");
  const fsUrl = `${fsHost}/v1/projects/${projectId}/databases/(default)/documents/venues`;
  const fsRes = await fetch(fsUrl);
  const fsData = await fsRes.json();
  const allVenueIds = (fsData.documents || []).map(d => d.name.split('/').pop());
  console.log("  Venues in Firestore:", allVenueIds.length);
  console.log("  Venue IDs:", allVenueIds);
  const foundInFirestore = createdVenueId ? allVenueIds.includes(createdVenueId) : allVenueIds.length > 0;
  console.log("  Found created venue:", foundInFirestore);

  // ── Step 3: Confirm venue in listVenuesForAdmin ──
  console.log("\nStep 3: Checking listVenuesForAdmin (admin read path)...");
  const listRes = await fetch(`${baseUrl}/listVenuesForAdmin`, {
    method: 'POST',
    headers: HEADERS_ADMIN,
    body: JSON.stringify({ data: { limit: 50 } })
  });
  const listBody = await listRes.json();
  const adminVenues = listBody?.result?.items || listBody?.result?.data || listBody?.data || [];
  console.log("  Admin list count:", Array.isArray(adminVenues) ? adminVenues.length : "non-array");
  console.log("  Admin list response structure:", Object.keys(listBody?.result || {}));
  const foundInAdminList = Array.isArray(adminVenues)
    ? adminVenues.some(v => v.id === createdVenueId)
    : false;
  console.log("  Found in admin list:", foundInAdminList);

  // ── Step 4: Confirm app read path searchVenuesInBounds ──
  console.log("\nStep 4: Checking searchVenuesInBounds (app read path)...");
  const searchRes = await fetch(`${baseUrl}/searchVenuesInBounds`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-Firebase-AppCheck': 'local-dev-app-check' },
    body: JSON.stringify({
      data: {
        minLat: 31.85,
        maxLat: 31.95,
        minLng: 35.15,
        maxLng: 35.25,
      }
    })
  });
  const searchBody = await searchRes.json();
  const appVenues = searchBody?.result?.venues || searchBody?.result?.data || searchBody?.data || [];
  console.log("  Search response status:", searchRes.status);
  console.log("  App venues count:", Array.isArray(appVenues) ? appVenues.length : "non-array");
  console.log("  Search response structure:", Object.keys(searchBody?.result || {}));
  const foundInAppSearch = Array.isArray(appVenues)
    ? appVenues.some(v => v.id === createdVenueId)
    : false;
  console.log("  Found in app search:", foundInAppSearch);

  // ── Summary ──
  console.log("\n═══════════════════════════════════════════");
  console.log("  PARITY VERIFICATION REPORT");
  console.log("═══════════════════════════════════════════");
  console.log("  Admin env:      .env.local → 127.0.0.1:5001");
  console.log("  App env:        --dart-define=WAIN_USE_FIREBASE_EMULATORS=true → 127.0.0.1:5001");
  console.log("  Firestore:      127.0.0.1:8080");
  console.log("  Auth:           127.0.0.1:9099");
  console.log("  Functions:      127.0.0.1:5001");
  console.log("───────────────────────────────────────────");
  console.log("  Step 1 (Create):       ", createdVenueId ? "✅ PASS" : "❌ FAIL");
  console.log("  Step 2 (Firestore):    ", foundInFirestore ? "✅ PASS" : "❌ FAIL");
  console.log("  Step 3 (Admin List):   ", foundInAdminList ? "✅ PASS" : "❌ FAIL");
  console.log("  Step 4 (App Search):   ", foundInAppSearch ? "✅ PASS" : "❌ FAIL");
  console.log("───────────────────────────────────────────");

  const allPassed = createdVenueId && foundInFirestore && foundInAdminList && foundInAppSearch;
  if (allPassed) {
    console.log("  OVERALL:               ✅ PARITY CONFIRMED");
  } else {
    console.log("  OVERALL:               ❌ PARITY FAILED");
    if (!createdVenueId) console.log("  Blocker: adminCreateVenue did not return a venueId");
    if (!foundInFirestore) console.log("  Blocker: venue not found in raw Firestore documents");
    if (!foundInAdminList) console.log("  Blocker: venue not found in listVenuesForAdmin");
    if (!foundInAppSearch) console.log("  Blocker: venue not found in searchVenuesInBounds");
  }
  console.log("═══════════════════════════════════════════\n");
}

checkParity().catch(e => {
  console.error("Fatal error:", e);
  process.exit(1);
});
