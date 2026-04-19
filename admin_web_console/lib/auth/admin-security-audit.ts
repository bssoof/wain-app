export type AdminSecurityAuditSource =
  | "route-guards"
  | "admin-command-proxy";

export type AdminSecurityAuditEvent = {
  source: AdminSecurityAuditSource;
  eventType: string;
  reason: string;
  status?: number;
  path?: string;
  routeKey?: string;
  command?: string;
  correlationId?: string;
  serviceLabel?: string;
  sessionUid?: string;
  sessionRole?: string;
};

export type AdminSecurityAuditRecord = {
  timestamp: string;
  source: AdminSecurityAuditSource;
  eventType: string;
  reason: string;
  status?: number;
  path?: string;
  routeKey?: string;
  command?: string;
  correlationId?: string;
  serviceLabel?: string;
  sessionUid?: string;
  sessionRole?: string;
};

type EmitAuditOptions = {
  now?: () => Date;
  logger?: (message: string) => void;
};

export function emitAdminSecurityAudit(
  event: AdminSecurityAuditEvent,
  options: EmitAuditOptions = {},
): AdminSecurityAuditRecord {
  const now = options.now ?? (() => new Date());
  const logger = options.logger ?? ((message: string) => console.warn(message));
  const path = toNonEmptyString(event.path);
  const routeKey = toNonEmptyString(event.routeKey);
  const command = toNonEmptyString(event.command);
  const correlationId = toNonEmptyString(event.correlationId);
  const serviceLabel = toNonEmptyString(event.serviceLabel);
  const sessionUid = toNonEmptyString(event.sessionUid);
  const sessionRole = toNonEmptyString(event.sessionRole);

  const record: AdminSecurityAuditRecord = {
    timestamp: now().toISOString(),
    source: event.source,
    eventType: event.eventType,
    reason: event.reason,
    ...(isFiniteNumber(event.status) ? { status: event.status } : {}),
    ...(path ? { path } : {}),
    ...(routeKey ? { routeKey } : {}),
    ...(command ? { command } : {}),
    ...(correlationId ? { correlationId } : {}),
    ...(serviceLabel ? { serviceLabel } : {}),
    ...(sessionUid ? { sessionUid } : {}),
    ...(sessionRole ? { sessionRole } : {}),
  };

  logger(`[SECURITY_AUDIT] ${JSON.stringify(record)}`);
  return record;
}

function toNonEmptyString(value: unknown): string | undefined {
  if (typeof value !== "string") {
    return undefined;
  }

  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === "number" && Number.isFinite(value);
}