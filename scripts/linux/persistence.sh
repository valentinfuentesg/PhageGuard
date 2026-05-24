#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# persistence.sh - Read-only enumeration of common Linux persistence locations:
# cron, systemd units, and shell rc files. Emits JSON to stdout.

usage() {
  cat <<'EOF'
Usage: persistence.sh [--help]

Enumerates common persistence mechanisms (read-only):
  - cron files under /etc/cron.d, /etc/crontab, /etc/cron.{daily,hourly,weekly,monthly}
  - systemd unit files (enabled) via systemctl
  - shell rc files in the invoking user's home (.bashrc, .profile, .zshrc, ...)

Output: JSON { check, tools_missing, cron[], systemd[], shell_rc[] }.
Read-only. No files are modified; timestamps are preserved.
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

# --- cron files ---
cron_paths=(/etc/crontab /etc/cron.d /etc/cron.daily /etc/cron.hourly /etc/cron.weekly /etc/cron.monthly)
cron_files=()
for p in "${cron_paths[@]}"; do
  if [[ -f "$p" ]]; then
    cron_files+=("$p")
  elif [[ -d "$p" ]]; then
    while IFS= read -r f; do
      cron_files+=("$f")
    done < <(find "$p" -maxdepth 1 -type f 2>/dev/null)
  fi
done

cron_json="[]"
if [[ ${#cron_files[@]} -gt 0 ]]; then
  cron_json="$(
    for f in "${cron_files[@]}"; do
      mtime="$(stat -c '%y' "$f" 2>/dev/null || echo "")"
      owner="$(stat -c '%U' "$f" 2>/dev/null || echo "")"
      hash=""
      if command -v sha256sum >/dev/null 2>&1; then
        hash="$(sha256sum "$f" 2>/dev/null | cut -d' ' -f1 || echo "")"
      fi
      jq -n --arg path "$f" --arg mtime "$mtime" --arg owner "$owner" --arg hash "$hash" \
        '{ path: $path, mtime: $mtime, owner: $owner, sha256: $hash }'
    done | jq -s '.'
  )"
fi
if ! command -v sha256sum >/dev/null 2>&1; then
  tools_missing+=("sha256sum")
fi

# --- systemd enabled units ---
systemd_json="[]"
if command -v systemctl >/dev/null 2>&1; then
  systemd_json="$(
    systemctl list-unit-files --state=enabled --no-legend --no-pager 2>/dev/null \
      | jq -R -s '
          split("\n") | map(select(length > 0))
          | map(split(" +"; "x") | { unit: .[0], state: (.[1] // "") })
        '
  )"
else
  tools_missing+=("systemctl")
fi

# --- shell rc files in home ---
rc_json="[]"
home_dir="${HOME:-}"
if [[ -n "$home_dir" && -d "$home_dir" ]]; then
  rc_names=(.bashrc .bash_profile .profile .zshrc .zprofile .bash_login)
  rc_files=()
  for n in "${rc_names[@]}"; do
    [[ -f "$home_dir/$n" ]] && rc_files+=("$home_dir/$n")
  done
  if [[ ${#rc_files[@]} -gt 0 ]]; then
    rc_json="$(
      for f in "${rc_files[@]}"; do
        mtime="$(stat -c '%y' "$f" 2>/dev/null || echo "")"
        jq -n --arg path "$f" --arg mtime "$mtime" '{ path: $path, mtime: $mtime }'
      done | jq -s '.'
    )"
  fi
fi

missing_json="$(printf '%s\n' "${tools_missing[@]:-}" \
  | jq -R -s 'split("\n") | map(select(length > 0)) | unique')"

jq -n \
  --argjson cron "$cron_json" \
  --argjson systemd "$systemd_json" \
  --argjson shell_rc "$rc_json" \
  --argjson tools_missing "$missing_json" \
  '{
    check: "persistence",
    tools_missing: $tools_missing,
    cron: $cron,
    systemd: $systemd,
    shell_rc: $shell_rc
  }'
