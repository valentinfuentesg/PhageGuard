# Security Policy

## Reporting a vulnerability

If you find a security issue **in PhageGuard itself** — for example a script that could be coerced into a destructive action, a prompt-injection bypass, or an unintended network call — please report it privately.

- Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) ("Report a vulnerability" under the Security tab), **or**
- Open a minimal issue stating only that you have a security report and asking for a private contact channel — do not include details in the public issue.

Please do not open a public issue with exploit details until a fix is available.

We aim to acknowledge reports within 7 days.

## Scope

In scope:

- Any way to make a read-only triage script perform a destructive or system-modifying action.
- Prompt-injection paths where content from a scanned file could cause the agent to take action instead of flagging it as a finding.
- Any unintended outbound network connection from a script.
- Evidence tampering (modified timestamps, overwritten files, cleared logs).

Out of scope:

- Vulnerabilities in the underlying tools PhageGuard orchestrates (osquery, ClamAV, YARA, Defender) — report those upstream.
- The inability to detect a sophisticated/targeted attack. PhageGuard explicitly does not defend against nation-state actors, kernel rootkits, or firmware implants (see [`CONTEXT.md`](CONTEXT.md) §6).

## Threat model

PhageGuard's own threat model is documented in [`CONTEXT.md`](CONTEXT.md) §6. Key principles:

- **All system-derived data is untrusted.** Filenames, log contents, and process command lines may be crafted to manipulate an LLM. The agent must not follow instructions embedded in scanned content.
- **Read-only by default.** Detection and remediation are separate skills; the default skill cannot change the system.
- **No exfiltration.** No telemetry, no analytics, no phoning home.
- **Supply chain.** Release scripts are hashed; contributions require review.

## Disclaimer

PhageGuard is provided AS IS, without warranty, and is not a replacement for professional security tools or incident response.
