#!/bin/sh
: "${FAKE_CLAUDE_LOG:?set FAKE_CLAUDE_LOG to the file to record argv into}"
printf '%s\n' "$*" >> "$FAKE_CLAUDE_LOG"
state="${FAKE_CLAUDE_MCP:-}"
[ -n "$state" ] && [ "${1:-}" = mcp ] || exit 0
verb="${2:-}"
shift 2
name=""
while [ $# -gt 0 ]; do
  case "$1" in
    --) break ;;
    -s|--scope) shift ;;
    -*) ;;
    *) [ -n "$name" ] || name="$1" ;;
  esac
  shift
done
touch "$state"
case "$verb" in
  add)
    if grep -qx "$name" "$state"; then
      printf 'MCP server %s already exists in user config\n' "$name" >&2
      exit 1
    fi
    printf '%s\n' "$name" >> "$state"
    ;;
  remove)
    grep -qx "$name" "$state" || { printf 'No MCP server found with name: %s\n' "$name" >&2; exit 1; }
    grep -vx "$name" "$state" > "$state.tmp" || true
    mv "$state.tmp" "$state"
    ;;
  get)
    grep -qx "$name" "$state" || exit 1
    ;;
esac
exit 0
