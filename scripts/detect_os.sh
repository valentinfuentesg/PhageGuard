#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# detect_os.sh - Identify the host OS so the orchestrator can pick the right
# checks. Read-only. Emits JSON to stdout.

usage() {
  cat <<'EOF'
Usage: detect_os.sh [--help]

Detects the operating system of the local host and prints a JSON object:
  { "os", "distro", "version", "kernel", "hostname" }

Read-only. Makes no changes and no network calls. Linux is the only fully
supported target in Phase 1; other systems are reported but not triaged.
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

uname_s="$(uname -s 2>/dev/null || echo unknown)"
kernel="$(uname -r 2>/dev/null || echo unknown)"
hostname="$(hostname 2>/dev/null || echo unknown)"

os="unknown"
distro="unknown"
version="unknown"

case "$uname_s" in
  Linux)
    os="linux"
    if [[ -r /etc/os-release ]]; then
      # shellcheck disable=SC1091
      distro="$(. /etc/os-release && echo "${ID:-unknown}")"
      # shellcheck disable=SC1091
      version="$(. /etc/os-release && echo "${VERSION_ID:-unknown}")"
    fi
    ;;
  Darwin)
    os="macos"
    distro="macos"
    version="$(sw_vers -productVersion 2>/dev/null || echo unknown)"
    ;;
  *)
    os="$(printf '%s' "$uname_s" | tr '[:upper:]' '[:lower:]')"
    ;;
esac

supported="false"
if [[ "$os" == "linux" ]]; then
  supported="true"
fi

jq -n \
  --arg os "$os" \
  --arg distro "$distro" \
  --arg version "$version" \
  --arg kernel "$kernel" \
  --arg hostname "$hostname" \
  --argjson supported "$supported" \
  '{
    check: "detect_os",
    os: $os,
    distro: $distro,
    version: $version,
    kernel: $kernel,
    hostname: $hostname,
    phase1_supported: $supported
  }'
