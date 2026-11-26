#!/bin/sh
event="${1:-}"
sid="${CLAWEE_SID:-}"
[ -n "$sid" ] || exit 0
clawee="${CLAWEE_BIN:-clawee}"
command -v "$clawee" >/dev/null 2>&1 || exit 0

kind=""
text=""
case "$event" in
  UserPromptSubmit)
    frames="$("$clawee" message inbox --pending --format prompt 2>/dev/null)" || exit 0
    [ -z "$frames" ] || printf '%s\n' "$frames"
    exit 0
    ;;
  SessionStart|SessionEnd)
    [ -z "${GROK_HOOK_EVENT:-}" ] || exit 0
    cat 2>/dev/null | python3 -c '
import json, os, subprocess, sys
event, addr, clawee = sys.argv[1], "/" + sys.argv[2], sys.argv[3]
try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(ev, dict):
    sys.exit(0)
argv = [clawee, "sessions", "harness", addr, "claude-code"]
if event == "SessionEnd":
    if ev.get("reason") not in ("prompt_input_exit", "logout"):
        sys.exit(0)
    argv.append("--clear")
else:
    session = ev.get("session_id")
    start = os.environ.get("CLAUDE_PROJECT_DIR", "")
    if not isinstance(session, str) or not session or session.startswith("-") or not start:
        sys.exit(0)
    argv += [session, "--start-dir", os.path.abspath(start)]
    transcript = ev.get("transcript_path")
    if isinstance(transcript, str) and transcript:
        argv += ["--transcript", transcript]
try:
    subprocess.run(argv, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=20)
except Exception:
    pass
' "$event" "$sid" "$clawee" >/dev/null 2>&1 || true
    exit 0
    ;;
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
