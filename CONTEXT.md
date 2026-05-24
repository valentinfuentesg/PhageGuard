# PhageGuard — Project Context

> **Name:** PhageGuard.
> **Tagline:** Open-source security triage skills for AI coding agents.

---

## 1. What this project is

A toolkit of **agent skills** (in the Anthropic "skills" format) that lets any AI coding agent — Claude Code, OpenCode, Aider, Cline, etc. — perform **on-demand security triage** on the user's local system.

The agent inspects the system using standard, well-known tools (osquery, ClamAV, YARA, ps/ss/lsof, Defender CLI on Windows), correlates findings, and produces a structured human-readable report. The user stays in the loop for every action that changes the system.

## 2. What this project is NOT

State this clearly to manage expectations and avoid liability:

- **Not an antivirus.** Does not replace Defender, ClamAV, CrowdStrike, etc. It orchestrates them.
- **Not a real-time monitor.** No background daemon, no continuous scanning. On-demand only.
- **Not autonomous.** Never deletes, quarantines, or modifies the system without explicit per-action user confirmation.
- **Not a SIEM.** No log aggregation, no cloud, no multi-host.
- **Not a forensic suite.** Preserves evidence but doesn't replace tools like Velociraptor or GRR for incident response.
- **Not a vulnerability scanner.** Doesn't do CVE matching, network port scanning of remote hosts, or pentest tasks.

## 3. Why it exists (the gap)

Existing solutions fall into two buckets:

1. **Enterprise SIEM/XDR with AI bolted on** (Microsoft Security Copilot, CrowdStrike Charlotte, SentinelOne Purple AI, Sophos AI). Expensive, SaaS, designed for SOCs. Not accessible to individuals or small teams.
2. **Local antivirus** (Defender, ClamAV, Malwarebytes). Powerful but opaque — they don't explain findings, don't help you understand your system, and don't integrate with AI coding workflows.

**The gap:** a free, transparent, local-first tool that brings AI-assisted triage to individual technical users (devs, sysadmins, small business IT, security learners) via the agents they already use.

## 4. Target users

- Developers wanting to audit their own dev machine
- Sysadmins doing first-pass triage on a suspected compromise
- Small business IT without budget for enterprise XDR
- Security learners who want guided exploration of their system
- Bug bounty hunters / CTF players analyzing isolated VMs

## 5. Non-users (do not optimize for these)

- Enterprise SOC analysts (use Sentinel, Splunk, etc.)
- Incident responders doing deep forensics (use Velociraptor, KAPE, Volatility)
- Malware reverse engineers (use Ghidra, IDA, sandboxes)

## 6. Threat model

### What PhageGuard defends against
- Casual / commodity malware leaving obvious traces (persistence entries, suspicious processes, known-bad hashes)
- Misconfigurations and weakened security postures
- User curiosity ("is something weird going on?")

### What PhageGuard does NOT defend against
- Sophisticated targeted attacks / nation-state actors
- Rootkits that hide from standard OS APIs (kernel-level)
- Firmware/UEFI implants
- Live attackers actively responding to defender actions

### PhageGuard's own threat model (attacks against the tool itself)
- **Prompt injection via system output.** Filenames, log contents, process command lines may contain text crafted to manipulate the LLM. **All system-derived data is treated as untrusted input.** The agent must not follow instructions embedded in scanned content.
- **Privilege abuse.** The agent often runs with elevated permissions. Hard constraints on what it can do without confirmation.
- **Data exfiltration.** The skill must never transmit user data off the system without explicit consent. No telemetry. No "phone home."
- **Supply chain.** Scripts are signed/hashed in releases. Contributions require review.

## 7. Core design principles

1. **Read-only by default.** Detection and remediation are separate skills. The default skill cannot change anything.
2. **Transparency.** Every command executed is logged and shown to the user. No hidden actions.
3. **Local-first.** No cloud calls except optional, opt-in features (e.g., VirusTotal hash lookup with user's own API key).
4. **Delegate to specialists.** The LLM correlates and explains; it does not "detect malware" by itself. Real detection comes from YARA, ClamAV, Defender, osquery.
5. **Degrade gracefully.** If ClamAV isn't installed, skip that step and tell the user. Don't fail the whole run.
6. **Forensic-friendly.** Never destroy evidence. Quarantine copies before any deletion.
7. **Explain, don't just flag.** Every finding includes WHY it's flagged, evidence, and recommended action.

## 8. Roadmap

### Phase 0 — Foundation (week 1)
- Repo public on GitHub
- README, LICENSE (Apache 2.0), CONTRIBUTING, CODE_OF_CONDUCT, threat model
- CI with shellcheck + markdown linting
- 5–10 `good-first-issue` tickets

### Phase 1 — Linux MVP, read-only (weeks 2–4)
Single skill, single OS, zero destructive capability.

```
phageguard-skill/
├── SKILL.md
├── scripts/
│   ├── detect_os.sh
│   └── linux/
│       ├── inventory.sh         # ps, systemctl, installed packages
│       ├── network.sh           # ss, lsof, listening ports
│       ├── persistence.sh       # cron, systemd, shell rc files
│       ├── recent_changes.sh    # find -mtime, dpkg verify
│       └── suid_check.sh        # unusual SUID/SGID binaries
├── references/
│   └── linux_indicators.md      # what's normal vs suspicious
├── examples/
│   └── sample_report.json
└── tests/
    └── fixtures/                # mock system outputs
```

### Phase 2 — Tool integration (month 2)
- Wrappers over osquery, ClamAV, YARA
- Optional VirusTotal hash lookup (user-supplied API key)
- Graceful degradation when tools are absent

### Phase 3 — macOS + Windows (month 3)
- Same structure, OS-specific scripts
- Windows: PowerShell + `MpCmdRun.exe` wrapper

### Phase 4 — Remediation skill (month 4)
- Separate skill: `phageguard-remediate`
- Only after detection is proven reliable
- Quarantine before delete, mandatory dry-run, per-item confirmation

### Phase 5 — Differentiators (month 5+)
- `--explain` mode: didactic explanations for learners
- `--baseline` mode: hash known-good state, diff later
- Agent adapters: Claude Code, OpenCode, Aider, Cline
- Public benchmarks on known malware samples (in isolated VMs)

## 9. Output format (the artifact users actually receive)

Every run produces a `report.json` and a human summary. Schema (draft):

```json
{
  "run_id": "uuid",
  "timestamp": "ISO-8601",
  "host": { "os": "linux", "distro": "ubuntu-24.04", "hostname": "redacted" },
  "tools_used": ["ps", "ss", "clamav"],
  "tools_missing": ["yara"],
  "findings": [
    {
      "id": "F-001",
      "severity": "medium",
      "category": "persistence",
      "title": "Unusual cron entry in /etc/cron.d/",
      "evidence": { "path": "/etc/cron.d/update", "content_hash": "..." },
      "why_suspicious": "Cron job runs as root every minute, fetches from a non-standard URL",
      "recommended_action": "Review file contents; if unknown, quarantine"
    }
  ],
  "summary": "3 medium-severity findings, 0 high. ClamAV scan clean.",
  "next_steps": ["Review F-001", "Consider running deep scan"]
}
```

## 10. Success criteria (Phase 1)

- Runs cleanly on a fresh Ubuntu 24.04 VM in < 5 minutes
- Detects all of: unusual cron entries, suspicious SUID binaries, processes with deleted binary backing, listening ports on non-standard interfaces
- Zero false-positive-driven destructive actions (none possible by design)
- README + demo GIF gets 50+ stars in first month (visibility target, not validation)
- 3+ external contributors before Phase 2 ends

## 11. Anti-goals (things we explicitly will not add)

- Browser extensions
- Mobile support (iOS/Android)
- Cloud dashboards
- "AI confidence score" without underlying tool evidence
- Subscription / paid tiers
- Closed-source components

## 12. Legal / liability

- License: **Apache 2.0** (patent grant, contributor-friendly)
- README disclaimer: "Provided AS IS. Not a replacement for professional security tools or incident response."
- No warranty, no guarantee of detection.
- Users responsible for their own systems.
