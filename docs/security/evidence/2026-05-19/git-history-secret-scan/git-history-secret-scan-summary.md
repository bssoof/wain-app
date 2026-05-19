# Git History Secret Scan Summary

Date: 2026-05-19

## Scope

Local interim scan across all refs from:

```text
git rev-list --all
```

Commit count scanned:

```text
233
```

Dedicated tools were not available locally:

```text
gitleaks=NOT_FOUND
trufflehog=NOT_FOUND
```

This scan is an interim local check. It does not replace a release-blocking `gitleaks`,
`trufflehog`, or approved CI secret-scanning report.

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

## Broad Pattern Scan

A no-value-output `git grep` scan checked all commits and wrote commit/path matches only,
without printing matched secret values.

Broad pattern counts:

```text
private-key-path-matches=20
service-account-path-matches=5091
signing-material-path-matches=3588
tokens-path-matches=2407
```

Interpretation:

- `private-key` matches are documentation/review references to the security plan and triage files.
- `service-account`, `signing-material`, and `tokens` are intentionally broad patterns and include many code, docs, script, and test references.
- No high-confidence sensitive object path was found by the object-path scan.
- This remains a release blocker until a dedicated secret scanning tool verifies both current tree and full Git history.
