# Admin Web Console Environment Policy Matrix

Date: 2026-04-19
Scope: Phase 1 security containment policy for admin auth/session and callable transport.

## Policy Matrix

| Capability | local | staging | production |
| --- | --- | --- | --- |
| Header-based session (`x-wain-admin-*`) | allowed only with explicit unsafe flag | default off, explicit unsafe flag only | forbidden |
| `NEXT_PUBLIC_*_AUTH_TOKEN` | allowed for local diagnostics | forbidden | forbidden |
| `NEXT_PUBLIC_*_APP_CHECK_TOKEN` | allowed for local diagnostics | forbidden | forbidden |
| Fixture fallback for admin-critical reads | allowed | explicit only | forbidden |
| Missing role fallback to `super_admin` | forbidden | forbidden | forbidden |
| Server-side command proxy | optional | required for go-live rehearsal | mandatory |

## Enforced Changes (Phase 1)

1. Header-based session context is ignored unless `WAIN_ENABLE_UNSAFE_ADMIN_HEADER_SESSION` is explicitly enabled in non-production runtime.
2. Cookie-derived session no longer auto-falls back to `super_admin` when role is missing.
3. Production runtime rejects live callable transport when `NEXT_PUBLIC_WAIN_FINANCE_AUTH_TOKEN` or `NEXT_PUBLIC_WAIN_FINANCE_APP_CHECK_TOKEN` is set.
4. Dedicated `test:security` suite added and wired into CI (`admin-security` job).

## Required Follow-ups

1. Complete migration to server-side admin command proxy for finance/content/media mutation surfaces.
2. Remove operational dependency on public privileged token flows for any production path.
3. Keep `test:security` as required check before merge.
