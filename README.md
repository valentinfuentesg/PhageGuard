# PhageGuard

**Open-source security triage skills for AI coding agents.**

PhageGuard is a toolkit of [agent skills](https://docs.claude.com/en/docs/claude-code/skills) that lets any AI coding agent — Claude Code, OpenCode, Aider, Cline — perform **on-demand, read-only security triage** on your local system. It inspects the host using well-known tools (osquery, ClamAV, YARA, `ps`/`ss`/`lsof`, Defender on Windows), correlates the findings, and produces a structured, human-readable report. You stay in the loop for every action that could change your system.

> **Status: Phase 1 — Linux MVP, read-only.** Active early development. See [`CONTEXT.md`](CONTEXT.md) for the full scope and roadmap.

---

## What it is

- **Read-only by default.** The triage skill cannot delete, quarantine, or modify anything.
- **Transparent.** Every command it runs is shown to you. No hidden actions, no telemetry, no "phone home."
- **Local-first.** No cloud calls except optional, opt-in features you turn on yourself (e.g. a future VirusTotal hash lookup with your own API key).
- **A delegator, not a detector.** The LLM correlates and explains. Real detection signals come from deterministic tools — YARA rules, ClamAV signatures, osquery queries, known-bad hash lists.

## What it is NOT

- **Not an antivirus.** It orchestrates Defender/ClamAV; it does not replace them.
- **Not a real-time monitor.** On-demand only. No background daemon.
- **Not autonomous.** It never changes your system without explicit, per-action confirmation.
- **Not a SIEM, forensic suite, or vulnerability scanner.**

See [`CONTEXT.md`](CONTEXT.md) §2 for the full list of non-goals.

## Who it's for

Developers auditing their own machine, sysadmins doing first-pass triage on a suspected compromise, small-business IT without an enterprise XDR budget, and security learners who want guided exploration of their system.

## How it works

1. The agent loads [`SKILL.md`](SKILL.md), which tells it when and how to run a triage.
2. It detects the OS, then runs a set of self-contained, read-only scripts under `scripts/`.
3. Each script emits structured JSON — never freeform prose.
4. The agent correlates the outputs into a single `report.json` plus a plain-language summary. See [`examples/sample_report.json`](examples/sample_report.json) for the schema.

## Quick start (Linux, Phase 1)

> Requires `bash`, plus the tools listed in [`docs/dependencies.md`](docs/dependencies.md). Missing tools are recorded in the report and skipped — the run does not abort.

```bash
git clone https://github.com/USER/PhageGuard.git
cd PhageGuard
bash scripts/detect_os.sh
bash scripts/linux/inventory.sh --help
```

In an AI agent, point it at this repo and ask it to run a PhageGuard triage. The agent reads `SKILL.md` and drives the scripts for you.

## Security & threat model

PhageGuard treats **all system-derived data as untrusted input**. Filenames, log contents, and process command lines may contain text crafted to manipulate an LLM (prompt injection). The agent does not follow instructions embedded in scanned content — it flags them as findings. Full threat model: [`CONTEXT.md`](CONTEXT.md) §6 and [`SECURITY.md`](SECURITY.md).

## Contributing

We want external contributors. Start with [`CONTRIBUTING.md`](CONTRIBUTING.md) and the [`good first issue`](https://github.com/USER/PhageGuard/labels/good%20first%20issue) label. All contributions are reviewed; scripts must pass `shellcheck`.

## License & disclaimer

Licensed under [Apache 2.0](LICENSE).

**Provided AS IS. PhageGuard is not a replacement for professional security tools or incident response. It offers no warranty and no guarantee of detection. You are responsible for your own systems.**
