"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useState,
  type ReactNode,
} from "react";

import type { AdminSession } from "@/lib/auth/guard-api";
import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import { createDefaultMediaCommandTransport } from "@/lib/media/default-media-command-transport";
import { createMediaCommandClient } from "@/lib/media/media-command-client";
import type { MediaCommandTransport } from "@/lib/media/media-command-transport";
import type {
  MediaCommandRequestMap,
  MediaCommandResult,
  MediaCommandType,
} from "@/lib/media/media-command-contracts";
import {
  mapMediaErrorCodeToRuntimeState,
  type MediaActionRuntimeState,
} from "@/lib/media/media-surface-affordances";

type MediaCommandProviderValue = {
  session: AdminSession;
  runCommand: <T extends MediaCommandType>(
    runtimeKey: string,
    command: T,
    request: MediaCommandRequestMap[T],
  ) => Promise<MediaCommandResult<T>>;
  getRuntimeState: (runtimeKey: string) => MediaActionRuntimeState;
  getLastMessage: (runtimeKey: string) => string | undefined;
};

const MediaCommandContext = createContext<MediaCommandProviderValue | null>(null);

export function MediaCommandProvider({
  children,
  session,
  transport,
}: {
  children: ReactNode;
  session: AdminSession;
  transport?: MediaCommandTransport;
}) {
  const client = useMemo(
    () =>
      createMediaCommandClient(transport ?? createDefaultMediaCommandTransport()),
    [transport],
  );

  const [runtimeByKey, setRuntimeByKey] = useState<
    Record<string, MediaActionRuntimeState>
  >({});
  const [messageByKey, setMessageByKey] = useState<Record<string, string | undefined>>(
    {},
  );

  const runCommand = useCallback(
    async <T extends MediaCommandType>(
      runtimeKey: string,
      command: T,
      request: MediaCommandRequestMap[T],
    ): Promise<MediaCommandResult<T>> => {
      setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "pending" }));
      setMessageByKey((prev) => {
        const next = { ...prev };
        delete next[runtimeKey];
        return next;
      });

      const result = await client.execute({ session, command, request });

      if (result.ok) {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "success" }));
        setMessageByKey((prev) => ({
          ...prev,
          [runtimeKey]: `${labelForCommand(result.command)} تم بنجاح.`,
        }));
        return result;
      }

      setRuntimeByKey((prev) => ({
        ...prev,
        [runtimeKey]: mapMediaErrorCodeToRuntimeState(result.error.code),
      }));
      setMessageByKey((prev) => ({
        ...prev,
        [runtimeKey]: localizeAdminMessage(result.error.message),
      }));
      return result;
    },
    [client, session],
  );

  const getRuntimeState = useCallback(
    (runtimeKey: string): MediaActionRuntimeState => runtimeByKey[runtimeKey] ?? "idle",
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
    <MediaCommandContext.Provider value={value}>
      {children}
    </MediaCommandContext.Provider>
  );
}

export function useOptionalMediaCommands(): MediaCommandProviderValue | null {
  return useContext(MediaCommandContext);
}

function labelForCommand(command: MediaCommandType): string {
  switch (command) {
    case "media_soft_delete":
      return "الإخفاء من القائمة";
    case "media_quarantine":
      return "عزل الملف";
    case "media_reference_check":
      return "فحص الارتباط";
    case "media_purge":
      return "الحذف النهائي";
    default:
      return command;
  }
}
