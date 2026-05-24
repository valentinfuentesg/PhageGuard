# Test fixtures

Mock inputs and expected-shape outputs for PhageGuard checks. Each check should
have at least:

- a **known-good** sample (clean system, no findings expected), and
- a **known-bad** sample (contains a planted indicator a check should surface).

Fixtures are static text/JSON — they never touch a real system. They let
contributors test correlation logic and the report schema without a live host.

Naming: `<check>.good.json` / `<check>.bad.json` for script-output samples, and
`<check>.<case>.txt` for raw command-output samples a script would parse.

> Reminder: fixtures must not contain real host data, secrets, or live IPs.
> Use documentation ranges (192.0.2.0/24, 198.51.100.0/24, 203.0.113.0/24).
