"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";
import { useRouter } from "next/navigation";

import type { AdminSession } from "@/lib/auth/guard-api";
import { localizeAdminLabel, localizeAdminMessage } from "@/lib/admin/admin-localization";
import {
  createDefaultReviewModerationTransport,
  createReviewModerationClient,
  mapReviewErrorCodeToRuntimeState,
  type ReviewActionRuntimeState,
  type ReviewModerationAction,
  type ReviewModerationCommandRequest,
  type ReviewModerationCommandResult,
  type ReviewModerationTransport,
} from "@/lib/reviews";

type ReviewCommandProviderValue = {
  session: AdminSession;
  runCommand: (
    runtimeKey: string,
    action: ReviewModerationAction,
    request: ReviewModerationCommandRequest,
  ) => Promise<ReviewModerationCommandResult>;
  getRuntimeState: (runtimeKey: string) => ReviewActionRuntimeState;
  getLastMessage: (runtimeKey: string) => string | undefined;
};

const ReviewCommandContext = createContext<ReviewCommandProviderValue | null>(null);

export function ReviewCommandProvider({
  children,
  session,
  transport,
}: {
  children: ReactNode;
  session: AdminSession;
  transport?: ReviewModerationTransport;
}) {
  const client = useMemo(
    () =>
      createReviewModerationClient(
        transport ?? createDefaultReviewModerationTransport(),
      ),
    [transport],
  );
  const refreshRoute = useOptionalRouterRefresh();

  const [runtimeByKey, setRuntimeByKey] = useState<
    Record<string, ReviewActionRuntimeState>
  >({});
  const [messageByKey, setMessageByKey] = useState<Record<string, string | undefined>>(
    {},
  );

  const runCommand = useCallback(
    async (
      runtimeKey: string,
      action: ReviewModerationAction,
      request: ReviewModerationCommandRequest,
    ): Promise<ReviewModerationCommandResult> => {
      setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "pending" }));
      setMessageByKey((prev) => {
        const next = { ...prev };
        delete next[runtimeKey];
        return next;
      });

      const result = await client.execute({ session, action, request });

      if (result.ok) {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "success" }));
        setMessageByKey((prev) => ({
          ...prev,
          [runtimeKey]: `تم تنفيذ ${localizeAdminLabel(action)} بنجاح.`,
        }));
        // Refresh server snapshot so action availability/status reflects committed backend state.
        refreshRoute();
        return result;
      }

      setRuntimeByKey((prev) => ({
        ...prev,
        [runtimeKey]: mapReviewErrorCodeToRuntimeState(result.error.code),
      }));
      setMessageByKey((prev) => ({
        ...prev,
        [runtimeKey]: localizeAdminMessage(result.error.message),
      }));
      if (result.error.code === "conflict") {
        // Conflicts usually mean state changed remotely; refresh to sync row status.
        refreshRoute();
      }
      return result;
    },
    [client, refreshRoute, session],
  );

  const getRuntimeState = useCallback(
    (runtimeKey: string): ReviewActionRuntimeState => runtimeByKey[runtimeKey] ?? "idle",
    [runtimeByKey],
  );

  const getLastMessage = useCallback(
    (runtimeKey: string) => messageByKey[runtimeKey],
    [messageByKey],
  );

  const value = useMemo(
    () => ({
      session,
      runCommand,
      getRuntimeState,
      getLastMessage,
    }),
    [session, runCommand, getRuntimeState, getLastMessage],
  );

  return (
    <ReviewCommandContext.Provider value={value}>
      {children}
    </ReviewCommandContext.Provider>
  );
}

export function useOptionalReviewCommands(): ReviewCommandProviderValue | null {
  return useContext(ReviewCommandContext);
}

function useOptionalRouterRefresh(): () => void {
  try {
    const router = useRouter();
    return () => router.refresh();
  } catch {
    return () => {};
  }
}
