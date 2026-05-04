export function logSecurityAudit(
  event: string,
  payload: Record<string, unknown>,
): void {
  console.log(JSON.stringify({
    event,
    ...payload,
  }));
}
