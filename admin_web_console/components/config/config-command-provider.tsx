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
import {
  createConfigCommandClient,
  createDefaultConfigCommandTransport,
  mapConfigErrorCodeToRuntimeState,
  type ConfigCommandRequestMap,
  type ConfigCommandRuntimeState,
  type ConfigCommandTransport,
  type ConfigCommandType,
} from "@/lib/config";

type ConfigCommandProviderValue = {
  session: AdminSession;
  runCommand: <T extends ConfigCommandType>(
    runtimeKey: string,
    command: T,
    request: ConfigCommandRequestMap[T],
  ) => Promise<any>;
  getRuntimeState: (runtimeKey: string) => ConfigCommandRuntimeState;
  getLastMessage: (runtimeKey: string) => string | undefined;
};

const ConfigCommandContext = createContext<ConfigCommandProviderValue | null>(null);

export function ConfigCommandProvider({
  children,
  session,
  transport,
}: {
  children: ReactNode;
  session: AdminSession;
  transport?: ConfigCommandTransport;
}) {
  const client = useMemo(
    () => createConfigCommandClient(transport ?? createDefaultConfigCommandTransport()),
    [transport],
  );

  const [runtimeByKey, setRuntimeByKey] = useState<
    Record<string, ConfigCommandRuntimeState>
  >({});
  const [messageByKey, setMessageByKey] = useState<Record<string, string | undefined>>(
    {},
  );

  const runCommand = useCallback(
    async <T extends ConfigCommandType>(
      runtimeKey: string,
      command: T,
      request: ConfigCommandRequestMap[T],
    ) => {
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
          [runtimeKey]: `تم تنفيذ ${labelForCommand(command)} بنجاح.`,
        }));
        return result;
      }

      setRuntimeByKey((prev) => ({
        ...prev,
        [runtimeKey]: mapConfigErrorCodeToRuntimeState(result.error.code),
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
    (runtimeKey: string): ConfigCommandRuntimeState => runtimeByKey[runtimeKey] ?? "idle",
    [runtimeByKey],
  );

  const getLastMessage = useCallback(
    (runtimeKey: string): string | undefined => messageByKey[runtimeKey],
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
    <ConfigCommandContext.Provider value={value}>
      {children}
    </ConfigCommandContext.Provider>
  );
}

export function useOptionalConfigCommands(): ConfigCommandProviderValue | null {
  return useContext(ConfigCommandContext);
}

function labelForCommand(command: ConfigCommandType): string {
  switch (command) {
    case "config_upsert_draft":
      return "حفظ المسودة";
    case "config_review_draft":
      return "مراجعة المسودة";
    case "publish_config":
      return "نشر الإعدادات";
    case "rollback_config":
      return "استرجاع الإصدار";
    default:
      return command;
  }
}
