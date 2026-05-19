# Tracked Raw Artifact Redaction Summary

Date: 2026-05-20

## Action

The following tracked raw artifacts were removed from the current repository tree because
`gitleaks` reported secret-like values in them:

- `docs/deploys/*.log`
- `docs/security/evidence/2026-05-19/phase-0-baseline/secrets-rg-code-config-focused.txt`
- `docs/security/evidence/2026-05-19/phase-0-baseline/secrets-rg-current-tree.txt`
- `.tmp/probe_media_transport_authenticated.js`

These files were raw command/debug/probe artifacts. They are not source code and are already
covered by ignore policy for future generated logs/temp files.

## Follow-Up

Historical commits still contain prior versions of these raw artifacts. Production release
must still record one of the following:

- approved history rewrite/removal plan,
- credential revocation/rotation evidence for any confirmed real secret,
- or formal false-positive/risk acceptance for non-secret public configuration values.
