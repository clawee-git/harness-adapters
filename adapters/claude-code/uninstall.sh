#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
claude="${CLAUDE_BIN:-claude}"
marker="$settings.clawee-mcp"
if [ ! -f "$marker" ]; then
  :
elif ! command -v "$claude" >/dev/null 2>&1; then
  echo "claude not found: clawee MCP server left registered"
elif ! "$claude" mcp get clawee >/dev/null 2>&1; then
  rm -f "$marker"
  echo "clawee MCP server already removed from Claude Code"
elif "$claude" mcp remove --scope user clawee >/dev/null 2>&1; then
  rm -f "$marker"
  echo "clawee MCP server removed from Claude Code"
else
  echo "clawee MCP server not removed: claude mcp remove --scope user clawee failed"
fi
[ -f "$settings" ] || exit 0
python3 - "$settings" "$dir" <<'PY'
import json, shlex, sys
path, adir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f) or {}
hooks = cfg.get("hooks", {})
for event in ("Notification", "Stop", "UserPromptSubmit", "SessionStart", "SessionEnd"):
    cmds = (f"{shlex.quote(adir + '/hook.sh')} {event}", f"{adir}/hook.sh {event}")
    kept = []
    for e in hooks.get(event, []):
        e["hooks"] = [h for h in e.get("hooks", []) if h.get("command") not in cmds]
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
