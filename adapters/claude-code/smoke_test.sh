#!/bin/sh
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"
cp "$root/tools/fake-clawee.sh" "$tmp/bin/clawee"
chmod +x "$tmp/bin/clawee"
export PATH="$tmp/bin:$PATH"
export FAKE_CLAWEE_LOG="$tmp/argv.log"
: > "$FAKE_CLAWEE_LOG"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

unset CLAWEE_SID
printf '{"notification_type":"permission_prompt","message":"x"}' | sh "$here/hook.sh" Notification || fail "hook exited non-zero outside a session"
[ ! -s "$FAKE_CLAWEE_LOG" ] || fail "hook signalled without CLAWEE_SID"

export CLAWEE_SID=abcdef0123456789abcdef0123456789
printf '{"notification_type":"permission_prompt","message":"Allow rm -rf ./dist?"}' | sh "$here/hook.sh" Notification
printf '{"notification_type":"idle_prompt","message":"Claude is waiting for your input"}' | sh "$here/hook.sh" Notification
printf '{"stop_hook_active":false}' | sh "$here/hook.sh" Stop
printf 'not json' | sh "$here/hook.sh" Notification
printf '{}' | sh "$here/hook.sh" PreToolUse

want="sessions signal /$CLAWEE_SID permission Allow rm -rf ./dist?
sessions signal /$CLAWEE_SID question Claude is waiting for your input
sessions signal /$CLAWEE_SID done
sessions signal /$CLAWEE_SID question"
got="$(cat "$FAKE_CLAWEE_LOG")"
[ "$got" = "$want" ] || { printf 'argv log:\n%s\nwant:\n%s\n' "$got" "$want" >&2; fail "argv mismatch"; }

export CLAUDE_SETTINGS="$tmp/settings.json"
printf '{"permissions":{"allow":["Bash(ls)"]}}\n' > "$CLAUDE_SETTINGS"
sh "$here/install.sh" >/dev/null
sh "$here/install.sh" >/dev/null
python3 - "$CLAUDE_SETTINGS" "$here" <<'PY' || fail "install did not add exactly one hook per event, or lost existing keys"
import json, sys
cfg = json.load(open(sys.argv[1])); d = sys.argv[2]
assert cfg["permissions"]["allow"] == ["Bash(ls)"]
for ev in ("Notification", "Stop"):
    cmds = [h["command"] for e in cfg["hooks"][ev] for h in e["hooks"]]
    assert cmds == [f"{d}/hook.sh {ev}"], cmds
PY
sh "$here/uninstall.sh" >/dev/null
python3 - "$CLAUDE_SETTINGS" <<'PY' || fail "uninstall left hooks or lost existing keys"
import json, sys
cfg = json.load(open(sys.argv[1]))
assert "hooks" not in cfg, cfg
assert cfg["permissions"]["allow"] == ["Bash(ls)"]
PY
echo "claude-code adapter: ok"
