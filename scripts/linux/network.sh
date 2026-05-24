#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# network.sh - Read-only enumeration of listening sockets and the processes
# behind them. Emits JSON to stdout. Missing tools are reported, not fatal.

usage() {
  cat <<'EOF'
Usage: network.sh [--help]

Lists listening TCP/UDP sockets on the local host (via ss) along with the
local address, port, and owning process where available.

Output: JSON { check, tools_missing, listeners[] }.
Read-only. No connections are made; nothing is sent over the network.
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
listeners_json="[]"

if command -v ss >/dev/null 2>&1; then
  # -l listening, -t tcp, -u udp, -n numeric, -p process (process info needs privs)
  listeners_json="$(
    ss -lntup 2>/dev/null \
      | tail -n +2 \
      | jq -R -s '
          split("\n")
          | map(select(length > 0))
          | map(split(" +"; "x")
              | { proto: .[0], state: .[1], local: .[4], process: (.[6] // "") })
        '
  )"
else
  tools_missing+=("ss")
fi

missing_json="$(printf '%s\n' "${tools_missing[@]:-}" \
  | jq -R -s 'split("\n") | map(select(length > 0))')"

jq -n \
  --argjson listeners "$listeners_json" \
  --argjson tools_missing "$missing_json" \
  '{
    check: "network",
    tools_missing: $tools_missing,
    listener_count: ($listeners | length),
    listeners: $listeners
  }'
