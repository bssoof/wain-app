"use client";

import { useCallback, useMemo, useRef, useState } from "react";
import { EmailAuthProvider, reauthenticateWithCredential } from "firebase/auth";

import { localizeAdminMessage } from "@/lib/admin/admin-localization";
import { auth } from "@/lib/firebase/client";

import {
  isStepUpRequiredForCommand,
  type StepUpScope,
} from "./step-up-required";

export type StepUpEnsureResult =
  | { ok: true }
  | {
      ok: false;
      code: "step_up_required" | "unavailable";
      message: string;
      reason:
        | "cancelled"
        | "challenge_in_progress"
        | "status_unavailable"
        | "reauth_failed"
        | "issue_failed";
    };

export type StepUpEnsureOptions = {
  force?: boolean;
};

export type UseStepUpOptions = {
  scope: StepUpScope;
  statusEndpoint?: string;
  issueEndpoint?: string;
  fetchImpl?: typeof fetch;
  bypassInTests?: boolean;
  reauthenticateAndGetFreshIdToken?: (password: string) => Promise<string>;
};

export type StepUpModalState = {
  open: boolean;
  command?: string;
  pending: boolean;
  error?: string;
  lockoutExpiresAt?: string;
  returnFocusTo?: HTMLElement | null;
  onSubmit: (password: string) => Promise<void>;
  onClose: () => void;
};

export type UseStepUpResult = {
  ensureStepUp: (
    command: string,
    ensureOptions?: StepUpEnsureOptions,
  ) => Promise<StepUpEnsureResult>;
  modal: StepUpModalState;
};

const DEFAULT_STEP_UP_STATUS_ENDPOINT = "/api/admin/step-up/status";
const DEFAULT_STEP_UP_ISSUE_ENDPOINT = "/api/admin/step-up/issue";

type StepUpStatusResponse = {
  success?: boolean;
  required?: boolean;
  error?: unknown;
};

type StepUpIssueResponse = {
  success?: boolean;
  error?: unknown;
  retryAt?: unknown;
};

export function useStepUp(options: UseStepUpOptions): UseStepUpResult {
  const fetchImpl = options.fetchImpl ?? fetch;
  const shouldBypass =
    options.bypassInTests ?? process.env.NODE_ENV === "test";

  const [challengeCommand, setChallengeCommand] = useState<string | null>(null);
  const [challengePending, setChallengePending] = useState(false);
  const [challengeError, setChallengeError] = useState<string | undefined>(
    undefined,
  );
  const [lockoutExpiresAt, setLockoutExpiresAt] = useState<string | undefined>(
    undefined,
  );
  const [returnFocusTo, setReturnFocusTo] = useState<HTMLElement | null>(null);
  const resolverRef = useRef<((result: StepUpEnsureResult) => void) | null>(
    null,
  );

  const resolveChallenge = useCallback((result: StepUpEnsureResult) => {
    resolverRef.current?.(result);
    resolverRef.current = null;
    setChallengeCommand(null);
    setChallengePending(false);
    setChallengeError(undefined);
  }, []);

  const openChallengeForCommand = useCallback(
    (command: string): Promise<StepUpEnsureResult> => {
      const activeElement =
        typeof document === "undefined" ? null : document.activeElement;
      setReturnFocusTo(activeElement instanceof HTMLElement ? activeElement : null);
      setChallengeCommand(command);
      setChallengePending(false);
      setChallengeError(undefined);

      return new Promise<StepUpEnsureResult>((resolve) => {
        resolverRef.current = resolve;
      });
    },
    [],
  );

  const cancelChallenge = useCallback(() => {
    resolveChallenge({
      ok: false,
      code: "step_up_required",
      message: "STEP_UP_REQUIRED",
      reason: "cancelled",
    });
  }, [resolveChallenge]);

  const issueChallenge = useCallback(
    async (password: string): Promise<void> => {
      if (!resolverRef.current) {
        return;
      }

      setChallengePending(true);
      setChallengeError(undefined);

      try {
        const tokenIssuer =
          options.reauthenticateAndGetFreshIdToken ??
          defaultReauthenticateAndGetFreshIdToken;
        const freshIdToken = await tokenIssuer(password);

        const response = await fetchImpl(
          options.issueEndpoint ?? DEFAULT_STEP_UP_ISSUE_ENDPOINT,
          {
            method: "POST",
            cache: "no-store",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({
              idToken: freshIdToken,
              scope: options.scope,
            }),
          },
        );

        const payload = await parseJsonSafely<StepUpIssueResponse>(response);
        if (!response.ok || payload?.success !== true) {
          const retryAt = toValidIsoTimestamp(payload?.retryAt);
          if (retryAt) {
            setLockoutExpiresAt(retryAt);
          }
          setChallengePending(false);
          setChallengeError(
            mapStepUpIssueFailureMessage(response.status, payload?.error, retryAt),
          );
          return;
        }

        setLockoutExpiresAt(undefined);
        resolveChallenge({ ok: true });
      } catch (error) {
        setChallengePending(false);
        setChallengeError(mapStepUpReauthError(error));
      }
    },
    [
      fetchImpl,
      options.issueEndpoint,
      options.reauthenticateAndGetFreshIdToken,
      options.scope,
      resolveChallenge,
    ],
  );

  const ensureStepUp = useCallback(
    async (
      command: string,
      ensureOptions: StepUpEnsureOptions = {},
    ): Promise<StepUpEnsureResult> => {
      if (!isStepUpRequiredForCommand(options.scope, command)) {
        return { ok: true };
      }

      if (shouldBypass && ensureOptions.force !== true) {
        return { ok: true };
      }

      if (resolverRef.current) {
        return {
          ok: false,
          code: "unavailable",
          message: "Step-up challenge is already in progress.",
          reason: "challenge_in_progress",
        };
      }

      if (ensureOptions.force === true) {
        return openChallengeForCommand(command);
      }

      const statusUrl = new URL(
        options.statusEndpoint ?? DEFAULT_STEP_UP_STATUS_ENDPOINT,
        "https://wain-admin.web.app",
      );
      statusUrl.searchParams.set("scope", options.scope);
      statusUrl.searchParams.set("command", command);

      try {
        const response = await fetchImpl(statusUrl.pathname + statusUrl.search, {
          method: "GET",
          cache: "no-store",
        });
        const payload = await parseJsonSafely<StepUpStatusResponse>(response);

        if (!response.ok || payload?.success !== true) {
          return {
            ok: false,
            code: "unavailable",
            message: mapStepUpStatusFailureMessage(payload?.error),
            reason: "status_unavailable",
          };
        }

        if (payload.required !== true) {
          return { ok: true };
        }

        return openChallengeForCommand(command);
      } catch {
        return {
          ok: false,
          code: "unavailable",
          message: "تعذر التحقق من حالة تأكيد الهوية حاليًا.",
          reason: "status_unavailable",
        };
      }
    },
    [
      fetchImpl,
      openChallengeForCommand,
      options.scope,
      options.statusEndpoint,
      shouldBypass,
    ],
  );

  const modal = useMemo<StepUpModalState>(
    () => ({
      open: Boolean(challengeCommand),
      command: challengeCommand ?? undefined,
      pending: challengePending,
      error: challengeError,
      lockoutExpiresAt,
      returnFocusTo,
      onSubmit: issueChallenge,
      onClose: cancelChallenge,
    }),
    [
      cancelChallenge,
      challengeCommand,
      challengeError,
      challengePending,
      lockoutExpiresAt,
      returnFocusTo,
      issueChallenge,
    ],
  );

  return {
    ensureStepUp,
    modal,
  };
}

async function defaultReauthenticateAndGetFreshIdToken(
  password: string,
): Promise<string> {
  const normalizedPassword = password.trim();
  if (normalizedPassword.length === 0) {
    throw new Error("missing_password");
  }

  const currentUser = auth.currentUser;
  if (!currentUser) {
    throw new Error("auth/session_missing");
  }

  const email = currentUser.email?.trim();
  if (!email) {
    throw new Error("auth/email_missing");
  }

  const credential = EmailAuthProvider.credential(email, normalizedPassword);
  await reauthenticateWithCredential(currentUser, credential);
  return currentUser.getIdToken(true);
}

async function parseJsonSafely<T extends Record<string, unknown>>(
  response: Response,
): Promise<T> {
  const rawText = await response.text();
  if (!rawText) {
    return {} as T;
  }

  try {
    return JSON.parse(rawText) as T;
  } catch {
    return {} as T;
  }
}

function mapStepUpStatusFailureMessage(error: unknown): string {
  const message = toNonEmptyString(error);
  return (
    localizeAdminMessage(message) ?? "تعذر التحقق من حالة تأكيد الهوية حاليًا."
  );
}

function mapStepUpIssueFailureMessage(
  status: number,
  error: unknown,
  retryAt?: string,
): string {
  if (status === 429) {
    if (retryAt) {
      return "تم تجاوز عدد محاولات تأكيد الهوية. انتظر حتى انتهاء العدّاد ثم أعد المحاولة.";
    }
    return "تم إيقاف محاولات التأكيد مؤقتًا. انتظر قليلًا ثم أعد المحاولة.";
  }

  const message = toNonEmptyString(error);
  return localizeAdminMessage(message) ?? "تعذر إصدار جلسة تأكيد الهوية.";
}

function mapStepUpReauthError(error: unknown): string {
  const explicitCode = toNonEmptyString(
    error && typeof error === "object" ? (error as { code?: unknown }).code : undefined,
  );
  const fallbackCode = toNonEmptyString(
    error && typeof error === "object"
      ? (error as { message?: unknown }).message
      : undefined,
  );
  const code = explicitCode ?? fallbackCode;

  if (code === "auth/invalid-credential") {
    return "كلمة المرور غير صحيحة. حاول مرة أخرى.";
  }
  if (code === "auth/too-many-requests") {
    return "عدد المحاولات كبير. انتظر قليلًا ثم أعد المحاولة.";
  }
  if (code === "auth/network-request-failed") {
    return "تعذر الاتصال بخدمة التحقق. تحقق من الشبكة ثم أعد المحاولة.";
  }
  if (code === "auth/session_missing") {
    return "جلسة تسجيل الدخول غير متاحة. أعد تسجيل الدخول ثم حاول مرة أخرى.";
  }
  if (code === "auth/email_missing") {
    return "لا يوجد بريد مرتبط بالحساب الحالي لتأكيد الهوية.";
  }
  if (code === "missing_password") {
    return "أدخل كلمة المرور للمتابعة.";
  }

  const message = toNonEmptyString(
    error && typeof error === "object"
      ? (error as { message?: unknown }).message
      : undefined,
  );
  return localizeAdminMessage(message) ?? "تعذر تأكيد الهوية. أعد المحاولة.";
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function toValidIsoTimestamp(value: unknown): string | undefined {
  const raw = toNonEmptyString(value);
  if (!raw) {
    return undefined;
  }

  const parsedMs = Date.parse(raw);
  if (!Number.isFinite(parsedMs)) {
    return undefined;
  }

  return new Date(parsedMs).toISOString();
}
