# Admin Web DAST Blocker

Date: 2026-05-20
Scope: `admin_web_console`

## Objective

Run a dynamic application security test baseline scan against the Admin Web Console before release.

Preferred command from the assessment plan:

```powershell
docker run --rm -t owasp/zap2docker-stable zap-baseline.py -t http://127.0.0.1:3000 -r zap-admin-baseline.html
```

## Current Result

DAST was not executed in this local environment because Docker is not available in the current shell:

```powershell
docker --version
```

Result:

```text
docker: The term 'docker' is not recognized as a name of a cmdlet, function, script file, or executable program.
```

## Compensating Local Checks Run

The Admin Web security test suite passed:

```powershell
npm --prefix admin_web_console run test:security
```

Result:

```text
Test Files: 11 passed
Tests: 45 passed
```

The Admin Web secure build and bundle token sentinel scan passed:

```powershell
npm --prefix admin_web_console run build:secure
```

Result:

```text
[security-guard] No forbidden NEXT_PUBLIC privileged tokens detected.
Next.js build: Compiled successfully.
[bundle-scan] Passed. No sentinel/forbidden token values found in 986 .next files.
```

Build packaging follow-up completed:

```text
The initial secure build reported unexpected NFT file tracing involving
admin_web_console/lib/firebase/server.ts and app/api/admin/topup-proof/route.ts.
This was remediated by explicitly scoping the Next/Turbopack root to
admin_web_console and marking development-only service account file probing as
turbopackIgnore.

Validation after the change:
npm --prefix admin_web_console run build:secure

Result:
The NFT tracing warning no longer appears. The remaining Next.js warning is the
middleware-to-proxy deprecation warning.
```
```

## Release Impact

Status: DAST still blocked.

Release blocking: Yes until one of the following happens:

1. Docker/ZAP baseline scan runs against a controlled local or staging Admin Web URL and passes or has accepted findings.
2. An equivalent DAST scanner runs and evidence is attached.
3. Security Lead approves a time-boxed accepted exception with expiry and compensating controls.

## Required Follow-Up

When Docker or a staging URL is available:

1. Start the Admin Web Console against controlled QA/staging data.
2. Run OWASP ZAP baseline or equivalent DAST.
3. Save the HTML/JSON report under `docs/security/evidence/2026-05-19/`.
4. File any confirmed issues using the WAIN finding template.
