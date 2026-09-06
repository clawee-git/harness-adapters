#!/bin/sh
# uninstall.sh — remove exactly the two hooks install.sh added.
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
[ -f "$settings" ] || exit 0
python3 - "$settings" "$dir" <<'PY'
import json, sys
path, adir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f) or {}
hooks = cfg.get("hooks", {})
for event in ("Notification", "Stop"):
    cmd = f"{adir}/hook.sh {event}"
    kept = []
    for e in hooks.get(event, []):
        e["hooks"] = [h for h in e.get("hooks", []) if h.get("command") != cmd]
        if e["hooks"]:
            kept.append(e)
    if kept:
        hooks[event] = kept
    else:
        hooks.pop(event, None)
if not hooks:
    cfg.pop("hooks", None)
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"clawee hooks removed from {path}")
PY
