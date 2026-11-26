#!/bin/sh
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/proj" "$tmp/elsewhere"
cp "$root/tools/fake-clawee.sh" "$tmp/bin/clawee"
chmod +x "$tmp/bin/clawee"
export PATH="$tmp/bin:$PATH"
export HOME="$tmp/home"
export CODEX_HOME="$tmp/codex"
export FAKE_CLAWEE_LOG="$tmp/argv.log"
: > "$FAKE_CLAWEE_LOG"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

sess=019a7c3e-5b1d-7e22-9f00-0123456789ab
tr="$CODEX_HOME/sessions/2026/11/26/rollout-$sess.jsonl"
start_event() { printf '{"session_id":"%s","cwd":"%s","transcript_path":%s,"hook_event_name":"SessionStart","source":"%s","model":"gpt-5","permission_mode":"default"}' "$sess" "$tmp/proj" "$1" "$2"; }

unset CLAWEE_SID
start_event "\"$tr\"" startup | sh "$here/hook.sh" SessionStart || fail "hook exited non-zero outside a session"
[ ! -s "$FAKE_CLAWEE_LOG" ] || fail "hook reported without CLAWEE_SID"

export CLAWEE_SID=abcdef0123456789abcdef0123456789
for src in startup resume clear compact fork; do
  (cd "$tmp/elsewhere" && start_event "\"$tr\"" "$src" | sh "$here/hook.sh" SessionStart) || fail "SessionStart $src exited non-zero"
done
(cd "$tmp/elsewhere" && start_event null startup | sh "$here/hook.sh" SessionStart) || fail "null transcript exited non-zero"
(cd "$tmp/elsewhere" && start_event '""' startup | sh "$here/hook.sh" SessionStart) || fail "empty transcript exited non-zero"
printf '{"session_id":"%s","cwd":"%s","hook_event_name":"SessionEnd","reason":"other"}' "$sess" "$tmp/proj" | sh "$here/hook.sh" SessionEnd || fail "SessionEnd exited non-zero"
report="sessions harness /$CLAWEE_SID codex $sess --start-dir $tmp/proj"
want="$report --transcript $tr
$report --transcript $tr
$report --transcript $tr
$report --transcript $tr
$report --transcript $tr
$report
$report"
got="$(cat "$FAKE_CLAWEE_LOG")"
[ "$got" = "$want" ] || { printf 'argv log:\n%s\nwant:\n%s\n' "$got" "$want" >&2; fail "argv mismatch"; }

: > "$FAKE_CLAWEE_LOG"
printf 'not json' | sh "$here/hook.sh" SessionStart || fail "non-JSON exited non-zero"
printf '{"session_id":"%s","source":"startup"}' "$sess" | sh "$here/hook.sh" SessionStart || fail "no cwd exited non-zero"
printf '{"session_id":"-x","cwd":"%s"}' "$tmp/proj" | sh "$here/hook.sh" SessionStart || fail "option-shaped id exited non-zero"
start_event null startup | FAKE_CLAWEE_EXIT=1 sh "$here/hook.sh" SessionStart || fail "hook propagated a refused call"
: > "$FAKE_CLAWEE_LOG"
start_event null startup | CLAWEE_BIN="$tmp/no-such-clawee" sh "$here/hook.sh" SessionStart || fail "hook failed without clawee"
[ ! -s "$FAKE_CLAWEE_LOG" ] || fail "hook reported when it must stay silent: $(cat "$FAKE_CLAWEE_LOG")"

hooks="$CODEX_HOME/hooks.json"
out="$(sh "$here/install.sh")" || fail "install exited non-zero"
case "$out" in *"/hooks"*) ;; *) fail "install did not tell the user to approve the hook in /hooks: $out" ;; esac
sh "$here/install.sh" >/dev/null || fail "second install exited non-zero"
python3 - "$hooks" "$here" <<'PY' || fail "install did not add exactly one SessionStart hook"
import json, sys
cfg = json.load(open(sys.argv[1])); d = sys.argv[2]
assert sorted(cfg["hooks"]) == ["SessionStart"], cfg
cmds = [h["command"] for e in cfg["hooks"]["SessionStart"] for h in e["hooks"]]
assert cmds == [f"{d}/hook.sh SessionStart"], cmds
PY
sh "$here/uninstall.sh" >/dev/null || fail "uninstall exited non-zero"
sh "$here/uninstall.sh" >/dev/null || fail "second uninstall exited non-zero"
[ "$(cat "$hooks")" = "{}" ] || fail "uninstall left: $(cat "$hooks")"

cat > "$hooks" <<'JSON'
{"hooks": {"SessionStart": [{"matcher": "startup", "hooks": [{"type": "command", "command": "/opt/mine start"}]}], "Stop": [{"hooks": [{"type": "command", "command": "/opt/mine stop"}]}]}}
JSON
cp "$hooks" "$tmp/original.json"
sh "$here/install.sh" >/dev/null || fail "install over existing hooks exited non-zero"
[ -f "$hooks.clawee-bak" ] || fail "install kept no backup"
python3 - "$hooks" "$here" <<'PY' || fail "install over existing hooks did not keep them and add ours once"
import json, sys
cfg = json.load(open(sys.argv[1])); d = sys.argv[2]
assert [h["command"] for e in cfg["hooks"]["Stop"] for h in e["hooks"]] == ["/opt/mine stop"]
cmds = [h["command"] for e in cfg["hooks"]["SessionStart"] for h in e["hooks"]]
assert cmds == ["/opt/mine start", f"{d}/hook.sh SessionStart"], cmds
PY
sh "$here/uninstall.sh" >/dev/null || fail "uninstall over existing hooks exited non-zero"
python3 - "$hooks" "$tmp/original.json" <<'PY' || fail "uninstall removed hooks install did not add"
import json, sys
assert json.load(open(sys.argv[1])) == json.load(open(sys.argv[2]))
PY
spaced="$tmp/with space/codex"
mkdir -p "$tmp/with space"
cp -R "$here" "$spaced"
printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"%s/hook.sh SessionStart"}]}]}}\n' "$spaced" > "$hooks"
sh "$spaced/install.sh" >/dev/null || fail "install from a folder with a space exited non-zero"
cmd="$(python3 -c 'import json,sys; print([h["command"] for e in json.load(open(sys.argv[1]))["hooks"]["SessionStart"] for h in e["hooks"]][-1])' "$hooks")"
: > "$FAKE_CLAWEE_LOG"
start_event null startup | sh -c "$cmd" || fail "installed command from a folder with a space failed: $cmd"
[ "$(cat "$FAKE_CLAWEE_LOG")" = "$report" ] || fail "installed command from a folder with a space did not report: $(cat "$FAKE_CLAWEE_LOG")"
sh "$spaced/uninstall.sh" >/dev/null || fail "uninstall from a folder with a space exited non-zero"
[ "$(cat "$hooks")" = "{}" ] || fail "uninstall left quoted or legacy hooks: $(cat "$hooks")"
[ ! -e "$HOME/.codex" ] || fail "install touched HOME/.codex with CODEX_HOME set"
echo "codex adapter: ok"
