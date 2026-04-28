const fetch = require('node-fetch') || fetch;

async function run() {
  const projectId = "wain-d2e28";
  const baseUrl = `http://127.0.0.1:5001/${projectId}/us-central1`;

  // Create a quick venue right under 0,0
  await fetch(`${baseUrl}/adminCreateVenue`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'Authorization': 'Bearer owner' },
    body: JSON.stringify({
      data: {
        raw_id: "parity-venue",
        name_ar: "مقهى",
        lat: 0.1, lng: 0.1,
        categories: ["cafe"],
        correlationId: "e2e"
      }
    })
  });

  const res = await fetch(`${baseUrl}/searchVenuesInBounds`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      data: {
        minLat: 0.0,
        maxLat: 1.0,
        minLng: 0.0,
        maxLng: 1.0,
        timeOfDay: [],
        moods: [],
        occasions: [],
        meals: [],
        categories: ["cafe"]
      }
    })
  });

  const text = await res.text();
  console.log("Response:", text);
}
run().catch(console.error);
