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
import { useStepUp, type StepUpEnsureResult } from "@/lib/auth/use-step-up";
import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import { StepUpModal } from "@/components/auth/step-up-modal";
import { createFinanceCommandClient } from "@/lib/finance/command-client";
import type { FinanceCommandTransport } from "@/lib/finance/finance-command-transport";
import type {
  FinanceCommandErrorCode,
  FinanceCommandRequestMap,
  FinanceCommandResult,
  FinanceCommandType,
} from "@/lib/finance/command-contracts";
import { createFinanceCommandError } from "@/lib/finance/command-contracts";
import { createDefaultFinanceCommandTransport } from "@/lib/finance/default-command-transport";
import { mapErrorCodeToRuntimeState } from "@/lib/finance/surface-affordances";
import type { CommandRuntimeState } from "@/lib/finance/surface-affordances";

type FinanceCommandProviderValue = {
  session: AdminSession;
  runCommand: <T extends FinanceCommandType>(
    runtimeKey: string,
    command: T,
    request: FinanceCommandRequestMap[T],
  ) => Promise<FinanceCommandResult<T>>;
  getRuntimeState: (runtimeKey: string) => CommandRuntimeState;
  getLastErrorMessage: (runtimeKey: string) => string | undefined;
};

type FailedStepUpResult = Extract<StepUpEnsureResult, { ok: false }>;

const FinanceCommandContext = createContext<FinanceCommandProviderValue | null>(
  null,
);

export function FinanceCommandProvider({
  children,
  session,
  transport,
}: {
  children: ReactNode;
  session: AdminSession;
  transport?: FinanceCommandTransport;
}) {
  const client = useMemo(
    () =>
      createFinanceCommandClient(transport ?? createDefaultFinanceCommandTransport()),
    [transport],
  );
  const { ensureStepUp, modal } = useStepUp({ scope: "finance" });

  const [runtimeByKey, setRuntimeByKey] = useState<
    Record<string, CommandRuntimeState>
  >({});
  const [errorMessageByKey, setErrorMessageByKey] = useState<
    Record<string, string | undefined>
  >({});

  const runCommand = useCallback(
    async <T extends FinanceCommandType>(
      runtimeKey: string,
      command: T,
      request: FinanceCommandRequestMap[T],
    ): Promise<FinanceCommandResult<T>> => {
      setErrorMessageByKey((prev) => {
        const next = { ...prev };
        delete next[runtimeKey];
        return next;
      });

      const handleStepUpFailure = (
        stepUpResult: FailedStepUpResult,
      ): FinanceCommandResult<T> => {
        const fallbackErrorCode: FinanceCommandErrorCode =
          stepUpResult.code === "step_up_required" ? "step_up_required" : "unavailable";
        if (stepUpResult.reason === "cancelled") {
          setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "idle" }));
        } else {
          setRuntimeByKey((prev) => ({
            ...prev,
            [runtimeKey]: mapErrorCodeToRuntimeState(fallbackErrorCode),
          }));
          setErrorMessageByKey((prev) => ({
            ...prev,
            [runtimeKey]: stepUpResult.message,
          }));
        }

        return {
          ok: false,
          command,
          commandId: request.commandId,
          correlationId: request.correlationId,
          error: createFinanceCommandError(fallbackErrorCode, stepUpResult.message),
        };
      };

      const initialStepUpResult = await ensureStepUp(command);
      if (!initialStepUpResult.ok) {
        return handleStepUpFailure(initialStepUpResult);
      }

      const executeCommand = async (): Promise<FinanceCommandResult<T>> => {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "pending" }));
        return client.execute({ session, command, request });
      };

      let result = await executeCommand();
      if (!result.ok && result.error.code === "step_up_required") {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "idle" }));
        const renewedStepUpResult = await ensureStepUp(command, { force: true });
        if (!renewedStepUpResult.ok) {
          return handleStepUpFailure(renewedStepUpResult);
        }
        result = await executeCommand();
      }

      if (result.ok) {
        setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: "idle" }));
        return result;
      }

      const nextState = mapErrorCodeToRuntimeState(result.error.code);
      setRuntimeByKey((prev) => ({ ...prev, [runtimeKey]: nextState }));
      setErrorMessageByKey((prev) => ({
        ...prev,
        [runtimeKey]: localizeAdminMessage(result.error.message),
      }));
      return result;
    },
    [client, ensureStepUp, session],
  );

  const getRuntimeState = useCallback(
    (runtimeKey: string): CommandRuntimeState => runtimeByKey[runtimeKey] ?? "idle",
    [runtimeByKey],
  );

  const getLastErrorMessage = useCallback(
    (runtimeKey: string) => errorMessageByKey[runtimeKey],
    [errorMessageByKey],
  );

  const value = useMemo(
    () => ({
      session,
      runCommand,
      getRuntimeState,
      getLastErrorMessage,
    }),
    [session, runCommand, getRuntimeState, getLastErrorMessage],
  );

  return (
    <FinanceCommandContext.Provider value={value}>
      {children}
      <StepUpModal {...modal} />
    </FinanceCommandContext.Provider>
  );
}

export function useFinanceCommands(): FinanceCommandProviderValue {
  const ctx = useContext(FinanceCommandContext);
  if (!ctx) {
    throw new Error("useFinanceCommands must be used within FinanceCommandProvider");
  }
  return ctx;
}
