#!/bin/sh
event="${1:-}"
sid="${CLAWEE_SID:-}"
[ -n "$sid" ] || exit 0
clawee="${CLAWEE_BIN:-clawee}"
command -v "$clawee" >/dev/null 2>&1 || exit 0
case "$event" in
  SessionStart|SessionEnd) ;;
  *) exit 0 ;;
esac
cat 2>/dev/null | python3 -c '
import json, os, subprocess, sys
event, addr, clawee = sys.argv[1], "/" + sys.argv[2], sys.argv[3]
deliberate_end_reasons = frozenset()
try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(ev, dict) or ev.get("subagentType"):
    sys.exit(0)
argv = [clawee, "sessions", "harness", addr, "grok"]
if event == "SessionEnd":
    if ev.get("reason") not in deliberate_end_reasons:
        sys.exit(0)
    argv.append("--clear")
else:
    session = ev.get("sessionId") or ev.get("session_id")
    start = ev.get("cwd")
    if not isinstance(session, str) or not session or session.startswith("-"):
        sys.exit(0)
    if not isinstance(start, str) or not start:
        sys.exit(0)
    argv += [session, "--start-dir", os.path.abspath(start)]
try:
    subprocess.run(argv, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=8)
except Exception:
    pass
' "$event" "$sid" "$clawee" >/dev/null 2>&1 || true
exit 0
