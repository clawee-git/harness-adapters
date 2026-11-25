#!/bin/sh
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
for event in ("Notification", "Stop", "UserPromptSubmit"):
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
claude="${CLAUDE_BIN:-claude}"
marker="$settings.clawee-mcp"
if [ -f "$marker" ]; then
  echo "clawee MCP server already registered by this adapter"
elif ! command -v "$claude" >/dev/null 2>&1; then
  echo "claude not found: clawee MCP server not registered (run: claude mcp add --scope user clawee -- clawee mcp)"
elif "$claude" mcp add --scope user clawee -- clawee mcp >/dev/null 2>&1; then
  printf 'claude mcp add --scope user clawee -- clawee mcp\n' > "$marker"
  echo "clawee MCP server registered for Claude Code (user scope)"
else
  echo "clawee MCP server not registered: claude mcp add failed (one named clawee may exist already)"
fi
