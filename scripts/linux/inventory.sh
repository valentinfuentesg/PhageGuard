#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# inventory.sh - Read-only snapshot of running processes and enabled services.
# Emits JSON to stdout. Missing tools are reported, not fatal.

usage() {
  cat <<'EOF'
Usage: inventory.sh [--help]

Collects a read-only inventory of the local Linux host:
  - running processes (pid, user, command) via ps
  - enabled systemd services via systemctl (if present)

Output: JSON { check, tools_missing, processes[], services[] }.
Read-only. No system changes, no network calls.
EOF
}

if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required but not installed" >&2
  exit 1
fi

tools_missing=()

processes_json="[]"
if command -v ps >/dev/null 2>&1; then
  processes_json="$(
    ps -eo pid=,user=,comm=,args= 2>/dev/null \
      | jq -R -s '
          split("\n")
          | map(select(length > 0))
          | map(
              ( . | sub("^ +"; "") | split(" +"; "x") ) as $f
              | { pid: ($f[0] // ""), user: ($f[1] // ""), comm: ($f[2] // ""),
                  args: ($f[3:] | join(" ")) }
            )
        '
  )"
else
  tools_missing+=("ps")
fi

services_json="[]"
if command -v systemctl >/dev/null 2>&1; then
  services_json="$(
    systemctl list-unit-files --type=service --state=enabled --no-legend --no-pager 2>/dev/null \
      | jq -R -s '
          split("\n")
          | map(select(length > 0))
          | map(split(" +"; "x") | { unit: .[0], state: (.[1] // "") })
        '
  )"
else
  tools_missing+=("systemctl")
fi

missing_json="$(printf '%s\n' "${tools_missing[@]:-}" \
  | jq -R -s 'split("\n") | map(select(length > 0))')"

jq -n \
  --argjson processes "$processes_json" \
  --argjson services "$services_json" \
  --argjson tools_missing "$missing_json" \
  '{
    check: "inventory",
    tools_missing: $tools_missing,
    process_count: ($processes | length),
    service_count: ($services | length),
    processes: $processes,
    services: $services
  }'
