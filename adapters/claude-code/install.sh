#!/bin/sh
set -eu
dir="$(cd "$(dirname "$0")" && pwd)"
settings="${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}"
python3 - "$settings" .claude/settings.json .claude/settings.local.json <<'PY'
import json, sys
for path in sys.argv[1:]:
    try:
        with open(path) as f:
            enabled = (json.load(f) or {}).get("enabledPlugins") or {}
    except Exception:
        continue
    on = sorted(k for k, v in enabled.items() if v is True and k.split("@")[0] == "clawee")
    if on:
        print(f"the clawee plugin is enabled in {path} ({', '.join(on)}): it already carries these hooks and the MCP server; install.sh not run", file=sys.stderr)
        sys.exit(1)
print("note: managed settings and other projects' .claude/ settings are not checked for the clawee plugin", file=sys.stderr)
PY
mkdir -p "$(dirname "$settings")"
[ -f "$settings" ] || printf '{}\n' > "$settings"
cp -n "$settings" "$settings.clawee-bak" 2>/dev/null || true
python3 - "$settings" "$dir" <<'PY'
import json, shlex, sys
path, adir = sys.argv[1], sys.argv[2]
with open(path) as f:
    cfg = json.load(f) or {}
hooks = cfg.setdefault("hooks", {})
for event in ("Notification", "Stop", "UserPromptSubmit", "SessionStart", "SessionEnd"):
    cmd = f"{shlex.quote(adir + '/hook.sh')} {event}"
    legacy = f"{adir}/hook.sh {event}"
    entries = hooks.setdefault(event, [])
    for h in (h for e in entries for h in e.get("hooks", [])):
        if h.get("command") == legacy:
            h["command"] = cmd
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
if ! command -v "$claude" >/dev/null 2>&1; then
  echo "claude not found: clawee MCP server not registered (run: claude mcp add --scope user clawee -- clawee mcp)"
elif [ -f "$marker" ] && "$claude" mcp get clawee >/dev/null 2>&1; then
  echo "clawee MCP server already registered by this adapter"
elif "$claude" mcp add --scope user clawee -- clawee mcp >/dev/null 2>&1; then
  printf 'claude mcp add --scope user clawee -- clawee mcp\n' > "$marker"
  echo "clawee MCP server registered for Claude Code (user scope)"
else
  echo "clawee MCP server not registered: claude mcp add failed (one named clawee may exist already)"
fi
