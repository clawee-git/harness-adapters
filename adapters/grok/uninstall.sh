#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
file="${GROK_HOME:-$HOME/.grok}/hooks/clawee.json"
[ -f "$file" ] || exit 0
python3 - "$file" "$dir" <<'PY'
import json, os, sys
path, adir = sys.argv[1], sys.argv[2]
try:
    with open(path) as f:
        hooks = (json.load(f) or {}).get("hooks") or {}
    cmds = sorted(h.get("command") for es in hooks.values() for e in es for h in e.get("hooks", []))
except Exception:
    cmds = []
if cmds != sorted(f"{adir}/hook.sh {ev}" for ev in ("SessionStart", "SessionEnd")):
    print(f"{path} was not written by this adapter: left in place")
    sys.exit(0)
os.remove(path)
print(f"clawee hooks removed: {path}")
PY
