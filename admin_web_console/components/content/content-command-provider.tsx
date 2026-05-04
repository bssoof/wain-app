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
import { localizeAdminLabel, localizeAdminMessage } from "@/lib/admin/admin-localization";

import {
  createContentModerationClient,
  type ContentModerationCommandResult,
} from "@/lib/content/content-command-client";
import type {
  ModerateOfferCommand,
  ModerateStoryCommand,
  ContentModerationAction,
} from "@/lib/content/content-command-contracts";
import type { ContentCommandTransport } from "@/lib/content/content-command-transport";
import {
  mapContentErrorCodeToRuntimeState,
  type ContentActionRuntimeState,
} from "@/lib/content/content-surface-affordances";
import { DefaultContentCommandTransport } from "../../lib/content/default-content-command-transport";

type ContentCommandContextValue = {
  session: AdminSession;
  runOfferCommand: (
    runtimeKey: string,
    action: ContentModerationAction,
    request: ModerateOfferCommand,
  ) => Promise<ContentModerationCommandResult>;
  runStoryCommand: (
    runtimeKey: string,
    action: ContentModerationAction,
    request: ModerateStoryCommand,
  ) => Promise<ContentModerationCommandResult>;
  getRuntimeState: (runtimeKey: string) => ContentActionRuntimeState;
  getLastMessage: (runtimeKey: string) => string | undefined;
};

const ContentCommandContext = createContext<ContentCommandContextValue | null>(null);

export function ContentCommandProvider({
  children,
  session,
  transport,
}: {
  children: ReactNode;
  session: AdminSession;
  transport?: ContentCommandTransport;
}) {
  const client = useMemo(
    () =>
      createContentModerationClient(
        transport ?? new DefaultContentCommandTransport(),
      ),
    [transport],
  );

  const [runtimeByKey, setRuntimeByKey] = useState<
    Record<string, ContentActionRuntimeState>
  >({});
  const [messageByKey, setMessageByKey] = useState<Record<string, string | undefined>>(
    {},
  );

  const runOfferCommand = useCallback(
    async (
      runtimeKey: string,
      action: ContentModerationAction,
      request: ModerateOfferCommand,
    ): Promise<ContentModerationCommandResult> => {
      setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "pending" }));
      setMessageByKey((prev) => {
        const next = { ...prev };
        delete next[runtimeKey];
        return next;
      });

      const result = await client.executeOffer({ session, action, request });
      if (result.ok) {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "success" }));
        setMessageByKey((prev) => ({
          ...prev,
          [runtimeKey]: result.data.replay
            ? `تمت إعادة تنفيذ ${localizeAdminLabel(action)} بنجاح.`
            : `تم تنفيذ ${localizeAdminLabel(action)} بنجاح.`,
        }));
        return result;
      }

      setRuntimeByKey((prev) => ({
        ...prev,
        [runtimeKey]: mapContentErrorCodeToRuntimeState(result.error.code),
      }));
      setMessageByKey((prev) => ({
        ...prev,
        [runtimeKey]: localizeAdminMessage(result.error.message),
      }));
      return result;
    },
    [client, session],
  );

  const runStoryCommand = useCallback(
    async (
      runtimeKey: string,
      action: ContentModerationAction,
      request: ModerateStoryCommand,
    ): Promise<ContentModerationCommandResult> => {
      setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "pending" }));
      setMessageByKey((prev) => {
        const next = { ...prev };
        delete next[runtimeKey];
        return next;
      });

      const result = await client.executeStory({ session, action, request });
      if (result.ok) {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "success" }));
        setMessageByKey((prev) => ({
          ...prev,
          [runtimeKey]: result.data.replay
            ? `تمت إعادة تنفيذ ${localizeAdminLabel(action)} بنجاح.`
            : `تم تنفيذ ${localizeAdminLabel(action)} بنجاح.`,
        }));
        return result;
      }

      setRuntimeByKey((prev) => ({
        ...prev,
        [runtimeKey]: mapContentErrorCodeToRuntimeState(result.error.code),
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
    (runtimeKey: string): ContentActionRuntimeState =>
      runtimeByKey[runtimeKey] ?? "idle",
    [runtimeByKey],
  );

  const getLastMessage = useCallback(
    (runtimeKey: string) => messageByKey[runtimeKey],
    [messageByKey],
  );

  const value = useMemo<ContentCommandContextValue>(
    () => ({
      session,
      runOfferCommand,
      runStoryCommand,
      getRuntimeState,
      getLastMessage,
    }),
    [session, runOfferCommand, runStoryCommand, getRuntimeState, getLastMessage],
  );

  return (
    <ContentCommandContext.Provider value={value}>
      {children}
    </ContentCommandContext.Provider>
  );
}

export function useOptionalContentCommands(): ContentCommandContextValue | null {
  return useContext(ContentCommandContext);
}
