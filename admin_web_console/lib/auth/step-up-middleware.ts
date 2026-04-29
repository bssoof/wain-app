import "server-only";

import type { AdminSession } from "./guard-api";
import {
  STEP_UP_COOKIE_NAME,
  isStepUpRequiredForCommand,
  type StepUpScope,
} from "./step-up-required";
import {
  StepUpTokenError,
  verifyStepUpToken,
  type StepUpTokenPayload,
} from "./step-up-token";

export type StepUpGuardError = {
  code: "step_up_required";
  status: 403;
  message: "STEP_UP_REQUIRED";
  retryable: false;
  details: {
    reason: string;
    scope: StepUpScope;
    command: string;
  };
};

export type StepUpGuardResult =
  | {
      ok: true;
      required: boolean;
      payload?: StepUpTokenPayload;
    }
  | {
      ok: false;
      error: StepUpGuardError;
    };

export async function verifyStepUpForCommand(options: {
  request: Request;
  session: AdminSession | null;
  scope: StepUpScope;
  command: string;
  signingKey?: string | Buffer;
  nowMs?: number;
}): Promise<StepUpGuardResult> {
  if (!isStepUpRequiredForCommand(options.scope, options.command)) {
    return { ok: true, required: false };
  }

  if (!options.session) {
    return stepUpRequired("missing_session", options.scope, options.command);
  }

  const token = readCookieValue(
    options.request.headers.get("cookie"),
    STEP_UP_COOKIE_NAME,
  );
  if (!token) {
    return stepUpRequired("missing_token", options.scope, options.command);
  }

  try {
    const payload = await verifyStepUpToken(
      token,
      {
        scope: options.scope,
        subject: options.session.uid,
      },
      {
        signingKey: options.signingKey,
        nowMs: options.nowMs,
      },
    );

    return {
      ok: true,
      required: true,
      payload,
    };
  } catch (error) {
    return stepUpRequired(
      error instanceof StepUpTokenError ? error.code : "invalid_token",
      options.scope,
      options.command,
    );
  }
}

function stepUpRequired(
  reason: string,
  scope: StepUpScope,
  command: string,
): StepUpGuardResult {
  return {
    ok: false,
    error: {
      code: "step_up_required",
      status: 403,
      message: "STEP_UP_REQUIRED",
      retryable: false,
      details: {
        reason,
        scope,
        command,
      },
    },
  };
}

function readCookieValue(
  rawCookieHeader: string | null,
  cookieName: string,
): string | undefined {
  if (!rawCookieHeader) {
    return undefined;
  }

  const prefix = `${cookieName}=`;
  for (const segment of rawCookieHeader.split(";")) {
    const trimmed = segment.trim();
    if (!trimmed.startsWith(prefix)) {
      continue;
    }

    const rawValue = trimmed.slice(prefix.length);
    try {
      return decodeURIComponent(rawValue);
    } catch {
      return rawValue;
    }
  }

  return undefined;
}
