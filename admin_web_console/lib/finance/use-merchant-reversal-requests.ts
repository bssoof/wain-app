"use client";

import { useCallback, useEffect, useState } from "react";
import {
  collection,
  onSnapshot,
  orderBy,
  query,
  where,
  type DocumentSnapshot,
  type Firestore,
} from "firebase/firestore";

import { firestoreDb } from "@/lib/firebase/client";
import {
  toMerchantReversalRequest,
  type MerchantReversalRequest,
} from "@/lib/finance/read-models";

type MerchantReversalRequestsState = {
  requests: MerchantReversalRequest[];
  isLoading: boolean;
  error: string | null;
  refresh: () => void;
};

export function buildPendingMerchantReversalRequestsQuery(
  db: Firestore = firestoreDb,
) {
  return query(
    collection(db, "wallet_reversal_requests"),
    where("source", "==", "merchant"),
    where("status", "==", "pending_review"),
    orderBy("created_at", "desc"),
  );
}

function mapSnapshotDoc(doc: DocumentSnapshot): MerchantReversalRequest {
  return toMerchantReversalRequest({
    id: doc.id,
    data: () => doc.data() as Record<string, unknown>,
  });
}

function mapSubscriptionError(error: unknown): string {
  if (error instanceof Error && error.message.trim()) {
    return error.message;
  }
  return "تعذّر تحميل طلبات التجار حاليًا";
}

export function useMerchantReversalRequests(): MerchantReversalRequestsState {
  const [requests, setRequests] = useState<MerchantReversalRequest[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [refreshVersion, setRefreshVersion] = useState(0);

  const refresh = useCallback(() => {
    setRefreshVersion((version) => version + 1);
  }, []);

  useEffect(() => {
    setIsLoading(true);
    setError(null);

    const unsubscribe = onSnapshot(
      buildPendingMerchantReversalRequestsQuery(),
      (snapshot) => {
        setRequests(snapshot.docs.map(mapSnapshotDoc));
        setError(null);
        setIsLoading(false);
      },
      (subscriptionError) => {
        setError(mapSubscriptionError(subscriptionError));
        setIsLoading(false);
      },
    );

    return unsubscribe;
  }, [refreshVersion]);

  return { requests, isLoading, error, refresh };
}
