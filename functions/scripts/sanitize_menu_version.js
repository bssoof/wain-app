const admin = require('firebase-admin');

// Initialize app if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

function isLikelyCorruptOrNoisy(text) {
  if (!text) return true;
  if (text.length > 80) return true;
  
  const lower = text.toLowerCase();
  
  const noisyTokens = [
    'http', 'www.', 'googleapis.com', 'type.googleapis.com',
    'cloud vision api', 'enable it by visiting', 'permission_denied',
    'service_disabled', 'contact us', '"error"', '"status"', '"details"'
  ];
  
  if (noisyTokens.some(token => lower.includes(token))) return true;
  if (/^[:/]+/.test(text)) return true;
  if (/[{}\[\]]/.test(text)) return true;
  
  // High moji-bake detection
  const mojibakeChars = (text.match(/[\u00C0-\u00FF]/g) || []).length;
  if (mojibakeChars >= 3 && mojibakeChars > text.length * 0.3) return true;
  const replacementChars = (text.match(/[\uFFFD\uFFFE\uFFFF]/g) || []).length;
  if (replacementChars >= 2) return true;
  
  return false;
}

async function sanitizeMenuVersions(targetVenueId = null) {
  console.log('Starting Phase 0 Hotfix Sanitization...');
  
  let venuesQuery = db.collection('venues');
  if (targetVenueId && targetVenueId.trim() !== "") {
    venuesQuery = venuesQuery.where(admin.firestore.FieldPath.documentId(), '==', targetVenueId);
  }
  
  const venuesSnap = await venuesQuery.get();
  console.log(`Found ${venuesSnap.size} venues to check.`);
  
  let deletedItemsCount = 0;
  
  for (const doc of venuesSnap.docs) {
    const venueId = doc.id;
    const versionsRef = doc.ref.collection('menu_versions');
    const versionsSnap = await versionsRef.get();
    
    for (const vDoc of versionsSnap.docs) {
      const versionId = vDoc.id;
      const status = vDoc.data().status;
      
      // We process both draft and active versions where noise might be present
      if (status !== 'draft' && status !== 'active') {
        continue;
      }
      
      const itemsSnap = await vDoc.ref.collection('items').get();
      let batch = db.batch();
      let batchCount = 0;
      let localDeletedCount = 0;
      
      for (const itemDoc of itemsSnap.docs) {
        const item = itemDoc.data();
        const nameAr = item.name_ar || '';
        const category = item.category || '';
        
        if (isLikelyCorruptOrNoisy(nameAr) || isLikelyCorruptOrNoisy(category)) {
          console.log(`[DELETING] Venue: ${venueId} | Version: ${versionId} | Item: ${nameAr}`);
          batch.delete(itemDoc.ref);
          localDeletedCount++;
          deletedItemsCount++;
          batchCount++;
          
          if (batchCount >= 400) {
            await batch.commit();
            batch = db.batch();
            batchCount = 0;
          }
        }
      }
      
      if (batchCount > 0) {
        await batch.commit();
      }
      if (localDeletedCount > 0) {
        const newCount = itemsSnap.size - localDeletedCount;
        await vDoc.ref.update({
          item_count: Math.max(0, newCount),
          updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        console.log(`Cleaned ${localDeletedCount} noisy items from version ${versionId} (${status})`);
      }
    }
  }
  
  console.log(`\nSanitization Complete!`);
  console.log(`Total noisy/corrupt items deleted: ${deletedItemsCount}`);
  process.exit(0);
}

const targetVenueId = process.argv[2] || null;
sanitizeMenuVersions(targetVenueId).catch(err => {
  console.error(err);
  process.exit(1);
});
