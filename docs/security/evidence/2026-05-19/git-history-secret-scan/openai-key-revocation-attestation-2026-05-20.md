# OpenAI Key Revocation Attestation

Date: 2026-05-20
Recorded at: 2026-05-20T02:37:01+03:00

## Scope

This attestation covers the verified historical OpenAI API key reported by:

```text
trufflehog git file://. --only-verified --json --no-update
```

## Affected Historical Location

| Field | Value |
| --- | --- |
| Detector | OpenAI |
| Commit | `04be0317ddec0a0e26babfed2a6067d9529ba7ed` |
| File | `scripts/multi_agent/.env.example` |
| Line | 4 |

The raw secret value is intentionally not recorded in repository evidence.

## Owner Attestation

The repository owner stated that the exposed OpenAI key was revoked/rotated on 2026-05-20.

## Evidence Classification

Evidence strength: Owner attestation.

Recommended follow-up for formal external audit: attach a dashboard screenshot or API key inventory export showing the revoked key status, without exposing the key value.

## Residual Risk

The current repository tree contains placeholders only. Git history still contains the historical secret reference unless a separate, approved history rewrite is performed. Because the key has been attested as revoked, the remaining risk is limited to audit/history hygiene and should be tracked as a governance decision rather than an active usable credential exposure.
