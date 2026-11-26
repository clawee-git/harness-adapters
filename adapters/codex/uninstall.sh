#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
hooks="${CODEX_HOME:-$HOME/.codex}/hooks.json"
[ -f "$hooks" ] || exit 0
python3 - "$hooks" "$dir" <<'PY'
import json, shlex, sys
path, adir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f) or {}
cmds = (f"{shlex.quote(adir + '/hook.sh')} SessionStart", f"{adir}/hook.sh SessionStart")
hooks = cfg.get("hooks", {})
kept = []
for e in hooks.get("SessionStart", []):
    e["hooks"] = [h for h in e.get("hooks", []) if h.get("command") not in cmds]
    if e["hooks"]:
        kept.append(e)
if kept:
    hooks["SessionStart"] = kept
else:
    hooks.pop("SessionStart", None)
if not hooks:
    cfg.pop("hooks", None)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"clawee SessionStart hook removed from {path}")
PY
