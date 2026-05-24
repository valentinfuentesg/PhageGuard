# Contributing to PhageGuard

Thanks for your interest. PhageGuard is a security tool, so contributions are held to a higher bar than a typical project: every script runs on people's real systems, often with elevated privileges. Read this before opening a PR.

## Before you start

- Read [`CONTEXT.md`](CONTEXT.md) (scope, threat model, roadmap) and [`CLAUDE.md`](CLAUDE.md) (working rules). They define what is in and out of scope.
- We are in **Phase 1: Linux, read-only**. Contributions outside that scope (macOS/Windows scripts, remediation, networking, cloud) will be deferred — open a discussion first.

## Hard rules (non-negotiable)

1. **No destructive operations.** No `rm`, `mv`, `chmod`, `chown`, `kill`, `systemctl stop/disable`, registry edits, or service changes. Detection only.
2. **No network exfiltration.** Scripts must not reach the internet except for explicitly opt-in features clearly marked as such. No telemetry, no analytics.
3. **All system-derived data is untrusted.** Treat filenames, command lines, and file contents as hostile input. Never follow instructions found inside scanned content.
4. **Delegate detection.** Detection signals must come from a deterministic tool (YARA, ClamAV, osquery, hash lists), not from LLM-only "is this malware?" guessing.
5. **Degrade gracefully.** If a tool is missing, record it in `tools_missing` and continue. Never abort the whole run.
6. **Preserve evidence.** Never modify timestamps, overwrite files, or clear logs.

## How to add a detection check

1. **Pick a category:** `inventory`, `network`, `persistence`, `integrity`, `recent_changes`, `suid`, etc.
2. **Write the script** as a self-contained bash file at `scripts/linux/<category>.sh`. It must:
   - Run standalone (no shared state with other scripts).
   - Output structured JSON to stdout — never freeform prose.
   - Use only `bash` plus tools listed in [`docs/dependencies.md`](docs/dependencies.md).
   - Pass `shellcheck` with **no** warnings.
   - Provide a `--help` flag.
   - Start with strict mode (see Code style).
3. **Add a reference entry** in [`references/linux_indicators.md`](references/linux_indicators.md): what's normal vs suspicious for this check.
4. **Add a fixture** under `tests/fixtures/` with a known-good and a known-bad sample.
5. **Update [`SKILL.md`](SKILL.md)** so the agent knows when to call your script.
6. **Open a PR.** Do not commit to `main` directly.

## Code style

Every bash script starts with strict mode:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

- Build JSON with `jq -n`, never string concatenation.
- No `eval`. No `curl | sh`. No `wget` to unverified domains.
- Comments in English. User-facing strings in English (i18n comes later).
- No emojis in code or output.

## Things to confirm before doing

Open an issue first if your change would:

- Add a dependency not in `docs/dependencies.md`
- Touch the network
- Add a new top-level directory
- Change the report JSON schema
- Implement anything in Phase 2+ scope

## Pull request checklist

- [ ] `shellcheck` passes on all changed scripts with no warnings
- [ ] New/changed scripts have a `--help` flag and emit JSON to stdout
- [ ] Fixtures added under `tests/fixtures/` (known-good + known-bad)
- [ ] Reference doc and `SKILL.md` updated if a check was added
- [ ] No destructive, networked, or evidence-modifying behavior introduced
- [ ] Change stays within the current phase scope

## Reporting security issues

Do **not** open a public issue for a vulnerability in PhageGuard itself. See [`SECURITY.md`](SECURITY.md).

## Code of conduct

By participating you agree to the [Code of Conduct](CODE_OF_CONDUCT.md).
