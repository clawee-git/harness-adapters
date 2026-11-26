#!/bin/sh
event="${1:-}"
sid="${CLAWEE_SID:-}"
[ -n "$sid" ] || exit 0
clawee="${CLAWEE_BIN:-clawee}"
command -v "$clawee" >/dev/null 2>&1 || exit 0
[ "$event" = SessionStart ] || exit 0
cat 2>/dev/null | python3 -c '
import json, os, subprocess, sys
addr, clawee = "/" + sys.argv[1], sys.argv[2]
try:
    ev = json.load(sys.stdin)
except Exception:
    sys.exit(0)
if not isinstance(ev, dict):
    sys.exit(0)
session, start = ev.get("session_id"), ev.get("cwd")
if not isinstance(session, str) or not session or session.startswith("-"):
    sys.exit(0)
if not isinstance(start, str) or not start:
    sys.exit(0)
argv = [clawee, "sessions", "harness", addr, "codex", session, "--start-dir", os.path.abspath(start)]
transcript = ev.get("transcript_path")
if isinstance(transcript, str) and transcript:
    argv += ["--transcript", transcript]
try:
    subprocess.run(argv, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=20)
except Exception:
    pass
' "$sid" "$clawee" >/dev/null 2>&1 || true
exit 0
