#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
file="${GROK_HOME:-$HOME/.grok}/hooks/clawee.json"
[ -f "$file" ] || exit 0
python3 - "$file" "$dir" <<'PY'
import os, sys
path, adir = sys.argv[1], sys.argv[2]
sys.dont_write_bytecode = True
sys.path.insert(0, adir)
from ownership import owned
if not owned(path, adir):
    print(f"{path} was not written by this adapter: left in place")
    sys.exit(0)
os.remove(path)
print(f"clawee hooks removed: {path}")
PY
