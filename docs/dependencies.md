# Dependencies

PhageGuard scripts use only widely available, read-only command-line tools. Adding a tool to this list requires discussion (open an issue first) — see `CLAUDE.md`.

## Required (Phase 1, Linux)

| Tool   | Used for                                  | Usually preinstalled? |
|--------|-------------------------------------------|-----------------------|
| `bash` | Script runtime (strict mode)              | Yes                   |
| `jq`   | Constructing JSON output                  | Often; install if not |

## Used when present (graceful degradation)

If one of these is missing, the relevant script records it in `tools_missing` and continues.

| Tool        | Used for                                              |
|-------------|-------------------------------------------------------|
| `ps`        | Process inventory                                     |
| `ss`        | Listening sockets / ports                             |
| `lsof`      | Mapping ports/files to processes                      |
| `systemctl` | systemd unit enumeration (persistence)                |
| `crontab`   | User cron enumeration (persistence)                   |
| `find`      | Recently modified files, SUID/SGID enumeration        |
| `stat`      | File metadata (mtime, mode, owner) without modifying  |
| `sha256sum` | Content hashing for evidence                          |
| `dpkg`/`rpm`| Package verification (recent_changes)                 |

## Planned (Phase 2 — not yet used)

These are part of the roadmap and **must not** be required yet:

- `osquery` — structured system querying
- `clamav` (`clamscan`) — signature-based malware scanning
- `yara` — rule-based pattern matching

## Rules

- No tool that performs network I/O may be invoked without an explicit, opt-in, clearly marked feature flag.
- No tool that modifies system state may be used at all in the triage skill (read-only).
- If a script needs a tool not listed here, the PR must add it here **and** justify it in the linked issue.
