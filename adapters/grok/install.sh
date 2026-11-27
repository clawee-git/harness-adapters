#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
file="${GROK_HOME:-$HOME/.grok}/hooks/clawee.json"
mkdir -p "$(dirname "$file")"
python3 - "$file" "$dir" <<'PY'
import json, os, shlex, sys
path, adir = sys.argv[1], sys.argv[2]
sys.dont_write_bytecode = True
sys.path.insert(0, adir)
from ownership import owned
if os.path.exists(path) and not owned(path, adir):
    print(f"{path} was not written by this adapter: left in place, install.sh not run", file=sys.stderr)
    sys.exit(1)
hook = shlex.quote(adir + "/hook.sh")
cfg = {"hooks": {
    "SessionStart": [{"hooks": [{"type": "command", "command": f"{hook} SessionStart", "timeout": 10}]}],
    "SessionEnd": [{"hooks": [{"type": "command", "command": f"{hook} SessionEnd", "timeout": 10}]}],
}}
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"clawee hooks installed as {path}")
PY
