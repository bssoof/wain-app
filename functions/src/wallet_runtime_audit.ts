import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import { normalizeNumber } from "./shared/admin-surface-helpers";
import { db } from "./shared/firestore-db";
import { rebuildWalletReportForVenue } from "./wallet_runtime_mutations";

async function upsertWalletAuditEvent(
  id: string,
  payload: Record<string, unknown>,
): Promise<void> {
  await db.collection("wallet_audit_events").doc(id).set(payload, { merge: true });
}

export const onWalletEntryWrite = functions.firestore
  .document("merchant_wallets/{venueId}/entries/{entryId}")
  .onWrite(async (change, context) => {
    const venueId = context.params.venueId as string;
    const entryId = context.params.entryId as string;
    const now = Timestamp.now();

    if (change.after.exists) {
      const entry = change.after.data() ?? {};
      await upsertWalletAuditEvent(`entry_${entryId}`, {
        category: "wallet_entry",
        event_type: "wallet_entry",
        venue_id: venueId,
        entry_id: entryId,
        type: typeof entry.type === "string" ? entry.type : null,
        amount: normalizeNumber(entry.amount),
        currency: typeof entry.currency === "string" ? entry.currency : null,
        balance_after: normalizeNumber(entry.balance_after),
        feature_key: typeof entry.feature_key === "string" ? entry.feature_key : null,
        reference_type: typeof entry.reference_type === "string" ? entry.reference_type : null,
        reference_id: typeof entry.reference_id === "string" ? entry.reference_id : null,
        reversed_at: entry.reversed_at ?? null,
        reversed_by_uid: typeof entry.reversed_by_uid === "string" ? entry.reversed_by_uid : null,
        reversal_entry_id: typeof entry.reversal_entry_id === "string" ? entry.reversal_entry_id : null,
        created_at: entry.created_at instanceof Timestamp ? entry.created_at : now,
        updated_at: now,
      });
    }

    await rebuildWalletReportForVenue(venueId);
    return null;
  });
