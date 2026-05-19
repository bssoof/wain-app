# Evidence Redaction Note

During Firebase emulator execution, Firebase CLI debug output emitted the full process environment into stdout. The assessment evidence files were mechanically redacted to replace full environment dumps with `<redacted by security assessment: Firebase CLI emitted full process environment>` and to mask any `POSTHOG_API_KEY` value.

This preserves command/test result evidence while avoiding accidental storage of environment values in security evidence.
