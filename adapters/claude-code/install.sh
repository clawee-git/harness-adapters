#!/bin/sh
# install.sh — merge the two clawee hooks into ~/.claude/settings.json
# (or $CLAUDE_SETTINGS). Idempotent: an already-installed hook is not added
# twice. A backup settings.json.clawee-bak is written beside the file the
# first time it is changed. Nothing else in the file is touched.
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || printf '{}\n' > "$settings"
cp -n "$settings" "$settings.clawee-bak" 2>/dev/null || true
python3 - "$settings" "$dir" <<'PY'
import json, sys
path, adir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f) or {}
hooks = cfg.setdefault("hooks", {})
for event in ("Notification", "Stop"):
    cmd = f"{adir}/hook.sh {event}"
    entries = hooks.setdefault(event, [])
    present = any(h.get("command") == cmd for e in entries for h in e.get("hooks", []))
    if not present:
        entries.append({"hooks": [{"type": "command", "command": cmd}]})
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print(f"clawee hooks installed into {path}")
PY
