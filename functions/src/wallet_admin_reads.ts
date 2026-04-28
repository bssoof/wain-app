import * as functions from "firebase-functions/v1";
import { Timestamp } from "firebase-admin/firestore";

import { requireAppCheck } from "./shared/app-check";
import { requireAdminAccessWithDb } from "./shared/admin-auth";
import {
  clampFinanceReadLimit,
  loadVenueDisplayLabels,
  resolveWalletLedgerUiType,
} from "./shared/admin-surface-helpers";
import { db } from "./shared/firestore-db";
import {
  financeTimestampToIso,
  financeTimestampToMillis,
} from "./shared/finance-media-normalizers";

function parseFinanceIsoBoundMillis(raw: unknown): number | null {
  if (typeof raw !== "string" || raw.trim().length === 0) {
    return null;
  }

  const ms = Date.parse(raw.trim());
  return Number.isFinite(ms) ? ms : null;
}

/**
 * listMerchantTopUpRequestsForAdmin
 * Read-only queue for merchant top-up requests (admin only).
 */
export const listMerchantTopUpRequestsForAdmin = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    await requireAdminAccessWithDb(context, db);

    const now = Timestamp.now();
    const venueFilter =
      typeof data?.venueId === "string" ? data.venueId.trim() : "";
    const limit = clampFinanceReadLimit(data?.limit, 50, 1, 200);
    const statusFilterRaw = Array.isArray(data?.statuses)
      ? data.statuses.filter(
          (s: unknown): s is string => typeof s === "string",
        )
      : [];
    const statusFilter = statusFilterRaw
      .map((s: string) => s.trim())
      .filter(
        (s: string) =>
          s === "pending" || s === "credited" || s === "rejected",
      );
    const createdAfterMs = parseFinanceIsoBoundMillis(data?.createdAfter);
    const createdBeforeMs = parseFinanceIsoBoundMillis(data?.createdBefore);
    const fetchCap = Math.min(
      500,
      statusFilter.length > 0 || createdAfterMs !== null || createdBeforeMs !== null
        ? limit * 8
        : limit,
    );

    let query: FirebaseFirestore.Query = db.collection("merchant_topup_requests");
    if (venueFilter) {
      query = query.where("venue_id", "==", venueFilter);
    }
    query = query.orderBy("created_at", "desc").limit(fetchCap);

    const snap = await query.get();
    const picked: Array<{
      id: string;
      data: FirebaseFirestore.DocumentData;
    }> = [];

    for (const doc of snap.docs) {
      const row = doc.data();
      const createdMs = financeTimestampToMillis(row.created_at);
      if (createdAfterMs !== null && createdMs < createdAfterMs) {
        continue;
      }
      if (createdBeforeMs !== null && createdMs > createdBeforeMs) {
        continue;
      }
      const st = row.status;
      if (statusFilter.length > 0) {
        if (st !== "pending" && st !== "credited" && st !== "rejected") {
          continue;
        }
        if (!statusFilter.includes(st)) {
          continue;
        }
      }
      picked.push({ id: doc.id, data: row });
      if (picked.length >= limit) {
        break;
      }
    }

    const venueIds = picked
      .map((p) =>
        typeof p.data.venue_id === "string" ? p.data.venue_id.trim() : "",
      )
      .filter((id) => id.length > 0);
    const venueLabels = await loadVenueDisplayLabels(venueIds);

    const requests = picked.map((p) => {
      const row = p.data;
      const venueId =
        typeof row.venue_id === "string" ? row.venue_id.trim() : "";
      const requestedBy =
        typeof row.requested_by_uid === "string" ? row.requested_by_uid : "";
      const status =
        row.status === "pending" ||
        row.status === "credited" ||
        row.status === "rejected"
          ? row.status
          : "pending";
      const currency =
        row.currency === "USD" || row.currency === "ILS" ? row.currency : "ILS";
      const transferRef =
        typeof row.transfer_reference === "string" &&
        row.transfer_reference.trim().length > 0
          ? row.transfer_reference.trim()
          : "";
      const venueLabel = venueId ? venueLabels.get(venueId) ?? venueId : venueId;

      const out: Record<string, unknown> = {
        id: p.id,
        ...(venueId ? { venueId } : {}),
        userId: requestedBy,
        userName: venueLabel || requestedBy || "Merchant",
        amount: typeof row.amount === "number" ? row.amount : 0,
        currency,
        providerReference: transferRef,
        createdAt: financeTimestampToIso(row.created_at),
        status,
      };
      if (typeof row.reviewed_by_uid === "string" && row.reviewed_by_uid.trim()) {
        out.reviewedBy = row.reviewed_by_uid.trim();
      }
      if (row.reviewed_at) {
        out.reviewedAt = financeTimestampToIso(row.reviewed_at);
      }
      return out;
    });

    return {
      checkedAt: now.toMillis(),
      correlationId:
        typeof data?.correlationId === "string"
          ? data.correlationId.trim()
          : null,
      requests,
    };
  },
);

/**
 * listMerchantWalletLedgerEntriesForAdmin
 * Read-only wallet ledger entries across venues (admin only).
 */
export const listMerchantWalletLedgerEntriesForAdmin = functions.https.onCall(
  async (data, context) => {
    requireAppCheck(context);
    await requireAdminAccessWithDb(context, db);

    const now = Timestamp.now();
    const venueFilter =
      typeof data?.venueId === "string" ? data.venueId.trim() : "";
    const limit = clampFinanceReadLimit(data?.limit, 100, 1, 300);
    const typeFilterRaw = Array.isArray(data?.entryTypes)
      ? data.entryTypes.filter(
          (t: unknown): t is string => typeof t === "string",
        )
      : [];
    const typeFilter = typeFilterRaw
      .map((t: string) => t.trim().toLowerCase())
      .filter(
        (t: string) => t === "credit" || t === "debit" || t === "reversal",
      );
    const createdAfterMs = parseFinanceIsoBoundMillis(data?.createdAfter);
    const createdBeforeMs = parseFinanceIsoBoundMillis(data?.createdBefore);
    const fetchCap = Math.min(
      500,
      typeFilter.length > 0 || createdAfterMs !== null || createdBeforeMs !== null
        ? limit * 6
        : limit,
    );

    let snapshot: FirebaseFirestore.QuerySnapshot;
    if (venueFilter) {
      snapshot = await db
        .collection("merchant_wallets")
        .doc(venueFilter)
        .collection("entries")
        .orderBy("created_at", "desc")
        .limit(fetchCap)
        .get();
    } else {
      snapshot = await db
        .collectionGroup("entries")
        .orderBy("created_at", "desc")
        .limit(fetchCap)
        .get();
    }

    const matched: Array<{
      doc: FirebaseFirestore.QueryDocumentSnapshot;
      uiType: "credit" | "debit" | "reversal";
    }> = [];

    for (const doc of snapshot.docs) {
      if (!venueFilter) {
        const path = doc.ref.path;
        if (!path.startsWith("merchant_wallets/") || !path.includes("/entries/")) {
          continue;
        }
      }
      const row = doc.data();
      const vId =
        typeof row.venue_id === "string" ? row.venue_id.trim() : "";
      if (!vId) {
        continue;
      }
      if (venueFilter && vId !== venueFilter) {
        continue;
      }
      const createdMs = financeTimestampToMillis(row.created_at);
      if (createdAfterMs !== null && createdMs < createdAfterMs) {
        continue;
      }
      if (createdBeforeMs !== null && createdMs > createdBeforeMs) {
        continue;
      }
      const uiType = resolveWalletLedgerUiType(row);
      if (typeFilter.length > 0 && !typeFilter.includes(uiType)) {
        continue;
      }
      matched.push({ doc, uiType });
      if (matched.length >= limit) {
        break;
      }
    }

    const venueIds = matched.map((m) => {
      const v = m.doc.data().venue_id;
      return typeof v === "string" ? v.trim() : "";
    }).filter((id) => id.length > 0);
    const venueLabels = await loadVenueDisplayLabels(venueIds);

    const entries = matched.map(({ doc, uiType }) => {
      const row = doc.data();
      const venueId =
        typeof row.venue_id === "string" ? row.venue_id.trim() : "";
      const currencyRaw =
        typeof row.currency === "string" ? row.currency.trim().toUpperCase() : "ILS";
      const currency = currencyRaw === "USD" ? "USD" : "ILS";
      const amount =
        typeof row.amount === "number" ? Math.abs(row.amount) : 0;
      const reference =
        typeof row.reference_id === "string" && row.reference_id.trim().length > 0
          ? row.reference_id.trim()
          : typeof row.idempotency_key === "string" &&
              row.idempotency_key.trim().length > 0
            ? row.idempotency_key.trim()
            : doc.id;
      const note = typeof row.note === "string" ? row.note.trim() : "";
      const referenceType =
        typeof row.reference_type === "string" ? row.reference_type.trim() : "";
      const description =
        note.length > 0
          ? note
          : `${uiType} · ${referenceType.length > 0 ? referenceType : "wallet"}`;
      const createdBy =
        typeof row.created_by_uid === "string" ? row.created_by_uid.trim() : "";
      const venueLabel = venueLabels.get(venueId) ?? venueId;
      const actorLabel =
        row.created_by_type === "admin"
          ? "Admin operator"
          : venueLabel;

      return {
        id: doc.id,
        venueId,
        userId: createdBy.length > 0 ? createdBy : venueId,
        userName: actorLabel,
        type: uiType,
        amount,
        currency,
        description,
        reference,
        createdAt: financeTimestampToIso(row.created_at),
      };
    });

    return {
      checkedAt: now.toMillis(),
      correlationId:
        typeof data?.correlationId === "string"
          ? data.correlationId.trim()
          : null,
      entries,
    };
  },
);