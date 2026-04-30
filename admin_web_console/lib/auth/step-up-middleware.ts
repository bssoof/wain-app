import "server-only";

import {
  emitStepUpAuditEvent,
  resolveStepUpKeyVersionLabels,
  type StepUpAuditEvent,
} from "./step-up-audit";
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
  emitAuditEvent?: (event: StepUpAuditEvent) => Promise<unknown>;
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
      emitAuditEvent: options.emitAuditEvent,
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
      emitAuditEvent: options.emitAuditEvent,
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
            nowMs: options.nowMs,
            emitAuditEvent: options.emitAuditEvent,
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
      emitAuditEvent: options.emitAuditEvent,
    });
  }
}

function logStepUpKeyMatch(options: {
  event: StepUpVerifyKeyMatchEvent;
  command: string;
  session: AdminSession;
  nowMs?: number;
  emitAuditEvent?: (event: StepUpAuditEvent) => Promise<unknown>;
}): void {
  if (options.event.keySlot !== "previous") {
    return;
  }

  const nowMs = options.nowMs ?? Date.now();
  const { currentKeyVersion, previousKeyVersion } =
    resolveStepUpKeyVersionLabels();
  void (options.emitAuditEvent ?? emitStepUpAuditEvent)({
    eventType: "step_up_previous_key_verified",
    userId: options.session.uid,
    sessionRole: options.session.primaryRole,
    command: options.command,
    scope: options.event.scope,
    tokenJti: options.event.jti,
    tokenIssuedAt: new Date(options.event.iat * 1000).toISOString(),
    tokenAge_ms: nowMs - options.event.iat * 1000,
    expiresAt: new Date(options.event.exp * 1000).toISOString(),
    currentKeyVersion,
    previousKeyVersion,
  }).catch((error) => {
    console.warn("[STEP_UP_AUDIT] Failed to emit previous-key audit event.", error);
  });
}

function stepUpFailureOrLogOnly(options: {
  reason: string;
  scope: StepUpScope;
  command: string;
  enforcementMode: StepUpEnforcementMode;
  session?: AdminSession;
  emitAuditEvent?: (event: StepUpAuditEvent) => Promise<unknown>;
}): StepUpGuardResult {
  if (options.enforcementMode !== "log_only") {
    return stepUpRequired(options.reason, options.scope, options.command);
  }

  void logStepUpLogOnlyWouldReject(options).catch((error) => {
    console.warn("[STEP_UP_AUDIT] Failed to emit log-only audit event.", error);
  });
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
  emitAuditEvent?: (event: StepUpAuditEvent) => Promise<unknown>;
}): Promise<unknown> {
  return (options.emitAuditEvent ?? emitStepUpAuditEvent)({
    eventType: "step_up_log_only_would_reject",
    enforcementMode: options.enforcementMode,
    reason: options.reason,
    command: options.command,
    scope: options.scope,
    userId: options.session?.uid,
    sessionRole: options.session?.primaryRole,
  });
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
