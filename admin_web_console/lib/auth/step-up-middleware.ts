import "server-only";

import type { AdminSession } from "./guard-api";
import {
  getStepUpEnforcementMode,
  type StepUpEnforcementMode,
} from "./step-up-config";
import {
  STEP_UP_COOKIE_NAME,
  isStepUpRequiredForCommand,
  type StepUpScope,
} from "./step-up-required";
import {
  StepUpTokenError,
  verifyStepUpToken,
  type StepUpTokenPayload,
  type StepUpVerifyKeyMatchEvent,
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
      enforcementMode?: StepUpEnforcementMode;
      bypassed?: boolean;
      bypassReason?: string;
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
  previousSigningKey?: string | Buffer;
  nowMs?: number;
  enforcementMode?: StepUpEnforcementMode;
  loadEnforcementMode?: () => Promise<StepUpEnforcementMode>;
}): Promise<StepUpGuardResult> {
  if (!isStepUpRequiredForCommand(options.scope, options.command)) {
    return { ok: true, required: false };
  }

  const enforcementMode =
    options.enforcementMode ??
    (await (options.loadEnforcementMode ?? getStepUpEnforcementMode)());
  if (enforcementMode === "disabled") {
    return {
      ok: true,
      required: true,
      enforcementMode,
      bypassed: true,
      bypassReason: "enforcement_disabled",
    };
  }

  if (!options.session) {
    return stepUpFailureOrLogOnly({
      reason: "missing_session",
      scope: options.scope,
      command: options.command,
      enforcementMode,
    });
  }
  const session = options.session;

  const token = readCookieValue(
    options.request.headers.get("cookie"),
    STEP_UP_COOKIE_NAME,
  );
  if (!token) {
    return stepUpFailureOrLogOnly({
      reason: "missing_token",
      scope: options.scope,
      command: options.command,
      enforcementMode,
      session,
    });
  }

  try {
    const payload = await verifyStepUpToken(
      token,
      {
        scope: options.scope,
        subject: session.uid,
      },
      {
        signingKey: options.signingKey,
        previousSigningKey: options.previousSigningKey,
        nowMs: options.nowMs,
        onVerifyKeyMatch: (event) =>
          logStepUpKeyMatch({
            event,
            command: options.command,
            session,
          }),
      },
    );

    return {
      ok: true,
      required: true,
      enforcementMode,
      payload,
    };
  } catch (error) {
    return stepUpFailureOrLogOnly({
      reason: error instanceof StepUpTokenError ? error.code : "invalid_token",
      scope: options.scope,
      command: options.command,
      enforcementMode,
      session,
    });
  }
}

function logStepUpKeyMatch(options: {
  event: StepUpVerifyKeyMatchEvent;
  command: string;
  session: AdminSession;
}): void {
  if (options.event.keySlot !== "previous") {
    return;
  }

  console.info(
    `[SECURITY_AUDIT] ${JSON.stringify({
      timestamp: new Date().toISOString(),
      source: "step-up-token",
      eventType: "step_up_previous_key_verified",
      keySlot: options.event.keySlot,
      command: options.command,
      scope: options.event.scope,
      sessionUid: options.session.uid,
      sessionRole: options.session.primaryRole,
      tokenJti: options.event.jti,
      expiresAt: new Date(options.event.exp * 1000).toISOString(),
    })}`,
  );
}

function stepUpFailureOrLogOnly(options: {
  reason: string;
  scope: StepUpScope;
  command: string;
  enforcementMode: StepUpEnforcementMode;
  session?: AdminSession;
}): StepUpGuardResult {
  if (options.enforcementMode !== "log_only") {
    return stepUpRequired(options.reason, options.scope, options.command);
  }

  logStepUpLogOnlyWouldReject(options);
  return {
    ok: true,
    required: true,
    enforcementMode: options.enforcementMode,
    bypassed: true,
    bypassReason: options.reason,
  };
}

function logStepUpLogOnlyWouldReject(options: {
  reason: string;
  scope: StepUpScope;
  command: string;
  enforcementMode: StepUpEnforcementMode;
  session?: AdminSession;
}): void {
  console.info(
    `[SECURITY_AUDIT] ${JSON.stringify({
      timestamp: new Date().toISOString(),
      source: "step-up-token",
      eventType: "step_up_log_only_would_reject",
      enforcementMode: options.enforcementMode,
      reason: options.reason,
      command: options.command,
      scope: options.scope,
      sessionUid: options.session?.uid,
      sessionRole: options.session?.primaryRole,
    })}`,
  );
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
