#!/bin/sh
# hook.sh — the Claude Code adapter. Claude Code runs it as a hook with the
# event's JSON on stdin (the `Notification` and `Stop` events; see
# settings.snippet.json). It turns the event into ONE clawee attention
# signal for the session it runs in, and exits 0 whatever happens: signalling
# is best-effort and a hook must never get in Claude Code's way.
#
#   Notification  notification_type=permission_prompt  → permission <message>
#   Notification  anything else (idle_prompt, a question) → question <message>
#   Stop                                               → done
#
# Usage from settings.json: hook.sh <event>   where <event> is Notification|Stop.
# Environment: CLAWEE_SID (set by claweed in every session's shell); unset =
# not inside a clawee session = do nothing. CLAWEE_BIN overrides the cli path.
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
    # Read the event once; python3's json module is the only parser every
    # gateway host has. A missing/odd payload still yields a `question`.
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
