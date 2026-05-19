# Git History Secret Scan Summary

Date: 2026-05-19

## Scope

Local scan across all refs from:

```text
git rev-list --all
```

Commit count scanned:

```text
233
```

Dedicated tools are now available locally under `.tmp/security-tools`:

```text
gitleaks=v8.30.1
trufflehog=v3.95.3
```

The tools were downloaded from their GitHub release assets after `winget` source lookup failed
on this machine.

## High-Confidence Sensitive Path Scan

Command class:

```text
git rev-list --objects --all | Select-String service-account-key/.env/jks/keystore/p12/pem/key.json paths
```

Result:

```text
NO_OBJECT_PATH_MATCHES
```

Evidence:

```text
git-object-sensitive-paths.txt
```

## Tool Results

After removing tracked raw log/probe/evidence artifacts from the current tree and adding a
narrow allowlist for intentionally public Firebase client API keys:

```text
gitleaks_current_tracked_after_redaction_findings=0
gitleaks_git_all_after_redaction_findings=0
trufflehog_verified_findings=1
```

Evidence:

```text
gitleaks-current-tracked-after-redaction-summary-2026-05-20.md
gitleaks-git-all-after-redaction-summary-2026-05-20.md
trufflehog-verified-summary-2026-05-20.txt
trufflehog-verified-finding-summary-2026-05-20.md
```

## Remediation Applied

- Removed tracked raw `docs/deploys/*.log` artifacts.
- Removed tracked raw phase-0 secret grep outputs that contained scanner matches.
- Removed tracked `.tmp/probe_media_transport_authenticated.js`.
- Added `.gitleaks.toml` to allow only public Firebase client API keys in known Firebase client config files.

## Remaining Note

TruffleHog found one verified historical OpenAI API key in commit
`04be0317ddec0a0e26babfed2a6067d9529ba7ed`, file
`scripts/multi_agent/.env.example`, line 4. The current file contains placeholders only,
but the historical key must be revoked and owner evidence must be recorded before release.

The local ignored file `scripts/multi_agent/.env` was also observed by an unrestricted workspace
scan, but it is ignored by `.gitignore` and not part of the tracked repository. Treat any real
values in ignored local `.env` files as local operator secrets and rotate/delete them outside
release evidence if they are no longer required.
