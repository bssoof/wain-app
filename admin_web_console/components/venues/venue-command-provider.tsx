"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import { localizeAdminLabel, localizeAdminMessage } from "@/lib/admin/admin-localization";
import type { AdminSession } from "@/lib/auth/guard-api";
import { createVenueCommandClient } from "@/lib/venues/venue-command-client";
import type {
  VenueCommandRequest,
  VenueCommandResult,
} from "@/lib/venues/venue-command-contracts";
import { createDefaultVenueCommandTransport } from "@/lib/venues/default-venue-command-transport";
import type { VenueManagementTransport } from "@/lib/venues/venue-command-adapters";

export type VenueActionRuntimeState =
  | "idle"
  | "pending"
  | "success"
  | "conflict"
  | "blocked"
  | "unavailable";

type VenueCommandContextValue = {
  session: AdminSession;
  runCommand: (
    runtimeKey: string,
    request: VenueCommandRequest,
  ) => Promise<VenueCommandResult<VenueCommandRequest["action"]>>;
  getRuntimeState: (runtimeKey: string) => VenueActionRuntimeState;
  getLastMessage: (runtimeKey: string) => string | undefined;
};

const VenueCommandContext = createContext<VenueCommandContextValue | null>(null);

export function VenueCommandProvider({
  children,
  session,
  transport,
}: {
  children: ReactNode;
  session: AdminSession;
  transport?: VenueManagementTransport;
}) {
  const client = useMemo(
    () =>
      createVenueCommandClient({
        session,
        transport: transport ?? createDefaultVenueCommandTransport(),
      }),
    [session, transport],
  );

  const [runtimeByKey, setRuntimeByKey] = useState<
    Record<string, VenueActionRuntimeState>
  >({});
  const [messageByKey, setMessageByKey] = useState<Record<string, string | undefined>>(
    {},
  );

  const runCommand = useCallback(
    async (
      runtimeKey: string,
      request: VenueCommandRequest,
    ): Promise<VenueCommandResult<VenueCommandRequest["action"]>> => {
      setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "pending" }));
      setMessageByKey((prev) => {
        const next = { ...prev };
        delete next[runtimeKey];
        return next;
      });

      const result = await client.execute(request as never);
      if (result.ok) {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "success" }));
        setMessageByKey((prev) => ({
          ...prev,
          [runtimeKey]: result.data.replay
            ? `تمت إعادة تنفيذ ${localizeAdminLabel(request.action)} بنجاح.`
            : `تم تنفيذ ${localizeAdminLabel(request.action)} بنجاح.`,
        }));
        return result;
      }

      setRuntimeByKey((prev) => ({
        ...prev,
        [runtimeKey]: mapVenueErrorCodeToRuntimeState(result.error.code),
      }));
      setMessageByKey((prev) => ({
        ...prev,
        [runtimeKey]: localizeAdminMessage(result.error.message),
      }));
      return result;
    },
    [client],
  );

  const getRuntimeState = useCallback(
    (runtimeKey: string): VenueActionRuntimeState => runtimeByKey[runtimeKey] ?? "idle",
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
    <VenueCommandContext.Provider value={value}>
      {children}
    </VenueCommandContext.Provider>
  );
}

export function useOptionalVenueCommands(): VenueCommandContextValue | null {
  return useContext(VenueCommandContext);
}

function mapVenueErrorCodeToRuntimeState(code: string): VenueActionRuntimeState {
  switch (code) {
    case "conflict":
      return "conflict";
    case "forbidden":
    case "validation_error":
      return "blocked";
    case "unauthorized":
    case "unavailable":
    default:
      return "unavailable";
  }
}
