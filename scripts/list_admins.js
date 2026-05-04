const admin = require("firebase-admin");

process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

admin.initializeApp({ projectId: "wain-d2e28" });

async function listAdmins() {
  console.log("Fetching Admins from Firestore Emulator...");
  try {
    const snapshot = await admin.firestore().collection("admins").get();

    if (snapshot.empty) {
      console.log("❌ No admin accounts found in the emulator!");
      return;
    }

    console.log("✅ Admin Accounts Found:");
    snapshot.forEach(doc => {
      console.log(`- ID: ${doc.id}`);
      console.log(`  Data: ${JSON.stringify(doc.data(), null, 2)}`);
    });
  } catch (error) {
    if (error.code === 'UNAVAILABLE') {
      console.error("❌ Could not connect to the emulator. Ensure the emulator is running.");
    } else {
      console.error("Error fetching admins:", error);
    }
  }
}

listAdmins();
