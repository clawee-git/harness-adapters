#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
hooks="${CODEX_HOME:-$HOME/.codex}/hooks.json"
mkdir -p "$(dirname "$hooks")"
[ -f "$hooks" ] || printf '{}\n' > "$hooks"
cp -n "$hooks" "$hooks.clawee-bak" 2>/dev/null || true
python3 - "$hooks" "$dir" <<'PY'
import json, sys
path, adir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f) or {}
cmd = f"{adir}/hook.sh SessionStart"
entries = cfg.setdefault("hooks", {}).setdefault("SessionStart", [])
if not any(h.get("command") == cmd for e in entries for h in e.get("hooks", [])):
    entries.append({"hooks": [{"type": "command", "command": cmd, "timeout": 20}]})
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"clawee SessionStart hook installed into {path}")
print("approve it in Codex before it runs: open codex and review the hook in /hooks")
PY
