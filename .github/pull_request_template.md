## Summary

<!-- What does this PR change and why? -->

## Scope check

- [ ] Stays within the current phase (Phase 1: Linux, read-only)
- [ ] No destructive operations (no rm/mv/chmod/kill/systemctl/registry/service changes)
- [ ] No network calls (or: opt-in feature clearly marked)
- [ ] Preserves evidence (no modified timestamps, overwritten files, cleared logs)

## Quality

- [ ] `shellcheck` passes with no warnings on changed scripts
- [ ] New/changed scripts have `--help` and emit JSON to stdout
- [ ] Fixtures added/updated under `tests/fixtures/` (known-good + known-bad)
- [ ] `references/linux_indicators.md` and `SKILL.md` updated if a check was added
- [ ] No new dependency outside `docs/dependencies.md` (or discussed in an issue)
