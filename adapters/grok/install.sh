#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
file="${GROK_HOME:-$HOME/.grok}/hooks/clawee.json"
mkdir -p "$(dirname "$file")"
python3 - "$file" "$dir" <<'PY'
import json, sys
path, adir = sys.argv[1], sys.argv[2]
cfg = {"hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": f"{adir}/hook.sh SessionStart", "timeout": 10}]}],
    "SessionEnd": [{"hooks": [{"type": "command", "command": f"{adir}/hook.sh SessionEnd", "timeout": 10}]}],
}}
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"clawee hooks installed as {path}")
PY
