#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# recent_changes.sh - Read-only listing of recently modified files in sensitive
# system paths. Emits JSON to stdout.

usage() {
  cat <<'EOF'
Usage: recent_changes.sh [--days N] [--help]

Lists files modified within the last N days (default: 7) under a fixed set of
sensitive paths (/etc, /usr/local/bin, /usr/local/sbin, /tmp, /var/tmp).

Output: JSON { check, days, tools_missing, files[] }.
Read-only. find is used without -exec; no file is opened for writing.
EOF
}

days=7
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --days) days="${2:-7}"; shift 2 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! [[ "$days" =~ ^[0-9]+$ ]]; then
  echo "error: --days must be a non-negative integer" >&2
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required but not installed" >&2
  exit 1
fi

tools_missing=()
files_json="[]"

if command -v find >/dev/null 2>&1; then
  search_paths=(/etc /usr/local/bin /usr/local/sbin /tmp /var/tmp)
  existing=()
  for p in "${search_paths[@]}"; do
    [[ -d "$p" ]] && existing+=("$p")
  done
  if [[ ${#existing[@]} -gt 0 ]]; then
    files_json="$(
      find "${existing[@]}" -xdev -type f -mtime "-${days}" 2>/dev/null \
        | while IFS= read -r f; do
            mtime="$(stat -c '%y' "$f" 2>/dev/null || echo "")"
            owner="$(stat -c '%U' "$f" 2>/dev/null || echo "")"
            mode="$(stat -c '%a' "$f" 2>/dev/null || echo "")"
            jq -n --arg path "$f" --arg mtime "$mtime" --arg owner "$owner" --arg mode "$mode" \
              '{ path: $path, mtime: $mtime, owner: $owner, mode: $mode }'
          done | jq -s '.'
    )"
  fi
else
  tools_missing+=("find")
fi

missing_json="$(printf '%s\n' "${tools_missing[@]:-}" \
  | jq -R -s 'split("\n") | map(select(length > 0))')"

jq -n \
  --argjson days "$days" \
  --argjson files "$files_json" \
  --argjson tools_missing "$missing_json" \
  '{
    check: "recent_changes",
    days: $days,
    tools_missing: $tools_missing,
    file_count: ($files | length),
    files: $files
  }'
