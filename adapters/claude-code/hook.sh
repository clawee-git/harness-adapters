#!/bin/sh
event="${1:-}"
sid="${CLAWEE_SID:-}"
[ -n "$sid" ] || exit 0
clawee="${CLAWEE_BIN:-clawee}"
command -v "$clawee" >/dev/null 2>&1 || exit 0

kind=""
text=""
case "$event" in
  Stop)
    kind="done"
    ;;
  Notification)
    payload="$(cat 2>/dev/null)"
    parsed="$(printf '%s' "$payload" | python3 -c '
import json, sys
try:
    ev = json.load(sys.stdin)
except Exception:
    ev = {}
t = str(ev.get("notification_type", "") or "")
m = str(ev.get("message", "") or "").replace("\n", " ").strip()
kind = "permission" if t == "permission_prompt" else "question"
print(kind)
print(m[:200])
' 2>/dev/null)"
    kind="$(printf '%s\n' "$parsed" | sed -n 1p)"
    text="$(printf '%s\n' "$parsed" | sed -n 2p)"
    [ -n "$kind" ] || kind="question"
    ;;
  *)
    exit 0
    ;;
esac

if [ -n "$text" ]; then
  "$clawee" sessions signal "/$sid" "$kind" "$text" >/dev/null 2>&1 || true
else
  "$clawee" sessions signal "/$sid" "$kind" >/dev/null 2>&1 || true
fi
exit 0
