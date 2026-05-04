const admin = require("firebase-admin");

process.env.FIREBASE_AUTH_EMULATOR_HOST = "127.0.0.1:9099";
process.env.FIRESTORE_EMULATOR_HOST = "127.0.0.1:8080";

admin.initializeApp({ projectId: "wain-d2e28" });

async function createAdmin(email, password, displayName) {
  try {
    let user;
    try {
      user = await admin.auth().getUserByEmail(email);
      console.log(`User ${email} already exists in Auth. Preserving user...`);
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        user = await admin.auth().createUser({
          email: email,
          password: password,
          displayName: displayName,
        });
        console.log(`✅ Created Auth User: ${user.uid}`);
      } else {
        throw e;
      }
    }

    await admin.firestore().collection("admins").doc(user.uid).set({
      name: displayName,
      email: email,
      role: "super_admin",
      roles: ["super_admin"],
      active: true,
      created_at: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    console.log(`✅ Granted Admin privilege in Firestore for: ${user.uid}`);

  } catch (error) {
    if (error.code === 'UNAVAILABLE') {
      console.error("❌ Could not connect to the emulator. Ensure the emulator is running.");
    } else {
      console.error("Error creating admin:", error);
    }
  }
}

// Default generic admin
createAdmin("admin@wain.app", "WainAdmin2026", "Wain Ultimate Admin");
