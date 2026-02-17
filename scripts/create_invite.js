/**
 * Create a merchant invite code in Firestore.
 * Usage: node scripts/create_invite.js [VENUE_ID]
 * 
 * If no VENUE_ID is provided, it will list the first 10 venues to choose from.
 */

const admin = require('firebase-admin');
const serviceAccount = require('../service-account-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function listVenues() {
  const snap = await db.collection('venues').limit(10).get();
  console.log('\n📍 أول 10 أماكن:');
  console.log('─'.repeat(60));
  snap.docs.forEach((doc, i) => {
    const d = doc.data();
    console.log(`${i + 1}. ${d.name_ar || d.name_en || 'N/A'}`);
    console.log(`   ID: ${doc.id}`);
    console.log(`   City: ${d.city || 'N/A'}`);
    console.log('');
  });
}

async function createInvite(venueId) {
  const code = 'WAIN-' + Math.random().toString(36).substring(2, 8).toUpperCase();
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 30 * 24 * 60 * 60 * 1000) // 30 days
  );

  await db.collection('merchant_invites').add({
    code: code,
    venue_id: venueId,
    status: 'active',
    created_at: now,
    expires_at: expiresAt,
    used_by: null,
    used_at: null,
  });

  // Get venue name
  const venueDoc = await db.collection('venues').doc(venueId).get();
  const venueName = venueDoc.data()?.name_ar || venueDoc.data()?.name_en || venueId;

  console.log('\n✅ تم إنشاء رمز الدعوة!');
  console.log('─'.repeat(40));
  console.log(`📌 الكود: ${code}`);
  console.log(`🏪 المحل: ${venueName}`);
  console.log(`📅 ينتهي: ${expiresAt.toDate().toLocaleDateString()}`);
  console.log('\nأرسل هذا الكود لصاحب المحل 🎉');
}

async function main() {
  const venueId = process.argv[2];

  if (!venueId) {
    console.log('❌ لم يتم تحديد venue_id\n');
    console.log('Usage: node scripts/create_invite.js VENUE_ID\n');
    await listVenues();
    console.log('شغّل الأمر مرة ثانية مع ID المحل:');
    console.log('node scripts/create_invite.js VENUE_ID_HERE\n');
  } else {
    await createInvite(venueId);
  }

  process.exit(0);
}

main().catch(console.error);
