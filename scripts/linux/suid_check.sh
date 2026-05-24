#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# suid_check.sh - Read-only enumeration of SUID/SGID binaries, flagging those
# outside the well-known set. Emits JSON to stdout.

usage() {
  cat <<'EOF'
Usage: suid_check.sh [--help]

Finds SUID/SGID files in standard binary paths and marks each as "expected"
(matches a conservative allowlist of common system binaries) or "unexpected".

Output: JSON { check, tools_missing, suid_files[] }, where each entry has
{ path, mode, owner, expected }.

Read-only. find is used without -exec; no file is modified.
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

# Conservative allowlist of commonly SUID/SGID binaries on mainstream distros.
# Anything not here is reported as "unexpected" for the analyst to review.
# An array is used deliberately: IFS is set to '\n\t' (no space), so a
# space-separated string would NOT word-split here.
expected_basenames=(
  sudo su passwd chsh chfn newgrp gpasswd mount umount ping ping6
  fusermount fusermount3 pkexec polkit-agent-helper-1
  dbus-daemon-launch-helper ssh-agent crontab at wall write expiry
  unix_chkpwd chage utempter newgidmap newuidmap mount.cifs
  pam_extrausers_chkpwd
)

is_expected() {
  local base="$1" w
  for w in "${expected_basenames[@]}"; do
    [[ "$base" == "$w" ]] && return 0
  done
  return 1
}

tools_missing=()
suid_json="[]"

if command -v find >/dev/null 2>&1; then
  search_paths=(/usr/bin /usr/sbin /bin /sbin /usr/local/bin /usr/local/sbin)
  existing=()
  for p in "${search_paths[@]}"; do
    [[ -d "$p" ]] && existing+=("$p")
  done
  if [[ ${#existing[@]} -gt 0 ]]; then
    suid_json="$(
      find "${existing[@]}" -xdev -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null \
        | while IFS= read -r f; do
            base="$(basename "$f")"
            mode="$(stat -c '%a' "$f" 2>/dev/null || echo "")"
            owner="$(stat -c '%U' "$f" 2>/dev/null || echo "")"
            if is_expected "$base"; then exp="true"; else exp="false"; fi
            jq -n --arg path "$f" --arg mode "$mode" --arg owner "$owner" --argjson expected "$exp" \
              '{ path: $path, mode: $mode, owner: $owner, expected: $expected }'
          done | jq -s '.'
    )"
  fi
else
  tools_missing+=("find")
fi

missing_json="$(printf '%s\n' "${tools_missing[@]:-}" \
  | jq -R -s 'split("\n") | map(select(length > 0))')"

jq -n \
  --argjson suid "$suid_json" \
  --argjson tools_missing "$missing_json" \
  '{
    check: "suid",
    tools_missing: $tools_missing,
    suid_count: ($suid | length),
    unexpected_count: ($suid | map(select(.expected == false)) | length),
    suid_files: $suid
  }'
