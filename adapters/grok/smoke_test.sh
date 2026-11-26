#!/bin/sh
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
tmp="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" "$tmp/home" "$tmp/repo/pkg/sub"
cp "$root/tools/fake-clawee.sh" "$tmp/bin/clawee"
chmod +x "$tmp/bin/clawee"
export PATH="$tmp/bin:$PATH"
export HOME="$tmp/home"
unset GROK_HOME
export FAKE_CLAWEE_LOG="$tmp/argv.log"
: > "$FAKE_CLAWEE_LOG"

fail() { printf 'FAIL: %s\n' "$1" >&2; exit 1; }

sess=019a7c40-1111-7222-8333-0123456789ab
ws="$tmp/repo"
launch="$tmp/repo/pkg/sub"
start_event() { printf '{"hookEventName":"session_start","hook_event_name":"SessionStart","sessionId":"%s","cwd":"%s","workspaceRoot":"%s","timestamp":"2026-11-26T06:00:00Z","permissionMode":"default","source":"%s"}' "$sess" "$launch" "$ws" "$1"; }
grok_env() { GROK_HOOK_EVENT="$1" GROK_SESSION_ID="$sess" GROK_WORKSPACE_ROOT="$ws" CLAUDE_PROJECT_DIR="$ws"; export GROK_HOOK_EVENT GROK_SESSION_ID GROK_WORKSPACE_ROOT CLAUDE_PROJECT_DIR; }

unset CLAWEE_SID
start_event new | sh "$here/hook.sh" SessionStart || fail "hook exited non-zero outside a session"
[ ! -s "$FAKE_CLAWEE_LOG" ] || fail "hook reported without CLAWEE_SID"

export CLAWEE_SID=abcdef0123456789abcdef0123456789
for src in new load; do
  (cd "$ws" && grok_env session_start && start_event "$src" | sh "$here/hook.sh" SessionStart) || fail "SessionStart $src exited non-zero"
done
(cd "$ws" && grok_env session_start && printf '{"session_id":"%s","cwd":"%s","source":"new"}' "$sess" "$launch" | sh "$here/hook.sh" SessionStart) || fail "snake-case id exited non-zero"
report="sessions harness /$CLAWEE_SID grok $sess --start-dir $launch"
want="$report
$report
$report"
got="$(cat "$FAKE_CLAWEE_LOG")"
[ "$got" = "$want" ] || { printf 'argv log:\n%s\nwant:\n%s\n' "$got" "$want" >&2; fail "argv mismatch"; }

: > "$FAKE_CLAWEE_LOG"
for reason in exit quit logout other prompt_input_exit ""; do
  printf '{"hook_event_name":"SessionEnd","sessionId":"%s","cwd":"%s","reason":"%s"}' "$sess" "$launch" "$reason" | sh "$here/hook.sh" SessionEnd || fail "SessionEnd $reason exited non-zero"
done
printf '{"hook_event_name":"SessionEnd","sessionId":"%s","cwd":"%s"}' "$sess" "$launch" | sh "$here/hook.sh" SessionEnd || fail "SessionEnd with no reason exited non-zero"
printf '{"hook_event_name":"SessionEnd","sessionId":"child","subagentType":"explore","reason":"exit"}' | sh "$here/hook.sh" SessionEnd || fail "subagent SessionEnd exited non-zero"
printf '{"hook_event_name":"SessionStart","sessionId":"child","cwd":"%s","subagentType":"explore","source":"new"}' "$launch" | sh "$here/hook.sh" SessionStart || fail "subagent SessionStart exited non-zero"
printf 'not json' | sh "$here/hook.sh" SessionStart || fail "non-JSON exited non-zero"
printf '{"sessionId":"%s","source":"new"}' "$sess" | sh "$here/hook.sh" SessionStart || fail "no cwd exited non-zero"
printf '{"sessionId":"-x","cwd":"%s"}' "$launch" | sh "$here/hook.sh" SessionStart || fail "option-shaped id exited non-zero"
start_event new | CLAWEE_BIN="$tmp/no-such-clawee" sh "$here/hook.sh" SessionStart || fail "hook failed without clawee"
[ ! -s "$FAKE_CLAWEE_LOG" ] || fail "hook reported when it must stay silent: $(cat "$FAKE_CLAWEE_LOG")"
start_event new | FAKE_CLAWEE_EXIT=1 sh "$here/hook.sh" SessionStart || fail "hook propagated a refused call"

file="$HOME/.grok/hooks/clawee.json"
mkdir -p "$HOME/.grok/hooks"
printf '{"hooks":{"Stop":[{"hooks":[{"type":"command","command":"/opt/mine"}]}]}}\n' > "$HOME/.grok/hooks/mine.json"
cp "$HOME/.grok/hooks/mine.json" "$tmp/mine.json"
sh "$here/install.sh" >/dev/null || fail "install exited non-zero"
sh "$here/install.sh" >/dev/null || fail "second install exited non-zero"
python3 - "$file" "$here" <<'PY' || fail "install did not write the clawee hook file"
import json, sys
cfg = json.load(open(sys.argv[1])); d = sys.argv[2]
hooks = cfg["hooks"]
assert sorted(hooks) == ["SessionEnd", "SessionStart"], hooks
for ev in hooks:
    hs = [h for e in hooks[ev] for h in e["hooks"]]
    assert [h["command"] for h in hs] == [f"{d}/hook.sh {ev}"], hs
end = hooks["SessionEnd"][0]["hooks"][0]
assert end["timeout"] >= 10, end
PY
cmp -s "$HOME/.grok/hooks/mine.json" "$tmp/mine.json" || fail "install touched another hook file"
sh "$here/uninstall.sh" >/dev/null || fail "uninstall exited non-zero"
sh "$here/uninstall.sh" >/dev/null || fail "second uninstall exited non-zero"
[ ! -e "$file" ] || fail "uninstall left the clawee hook file"
cmp -s "$HOME/.grok/hooks/mine.json" "$tmp/mine.json" || fail "uninstall touched another hook file"

printf '{"hooks":{}}\n' > "$file"
cp "$file" "$tmp/foreign.json"
out="$(sh "$here/uninstall.sh" 2>&1)" || fail "uninstall of a foreign clawee.json exited non-zero"
[ -f "$file" ] || fail "uninstall removed a clawee.json it did not write"
if out="$(sh "$here/install.sh" 2>&1)"; then fail "install overwrote a clawee.json it did not write"; fi
case "$out" in *"not written by this adapter"*) ;; *) fail "install refusal did not say why: $out" ;; esac
cmp -s "$file" "$tmp/foreign.json" || fail "install refusal changed the foreign file"
rm -f "$file"

spaced="$tmp/with space/grok"
mkdir -p "$tmp/with space"
cp -R "$here" "$spaced"
printf '{"hooks":{"SessionStart":[{"hooks":[{"type":"command","command":"%s/hook.sh SessionStart"}]}],"SessionEnd":[{"hooks":[{"type":"command","command":"%s/hook.sh SessionEnd"}]}]}}\n' "$spaced" "$spaced" > "$file"
sh "$spaced/install.sh" >/dev/null || fail "install over its own legacy file exited non-zero"
cmd="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["hooks"]["SessionStart"][0]["hooks"][0]["command"])' "$file")"
: > "$FAKE_CLAWEE_LOG"
start_event new | sh -c "$cmd" || fail "installed command from a folder with a space failed: $cmd"
[ "$(cat "$FAKE_CLAWEE_LOG")" = "$report" ] || fail "installed command from a folder with a space did not report: $(cat "$FAKE_CLAWEE_LOG")"
sh "$spaced/uninstall.sh" >/dev/null || fail "uninstall from a folder with a space exited non-zero"
[ ! -e "$file" ] || fail "uninstall left the quoted hook file"

export GROK_HOME="$tmp/grokhome"
sh "$here/install.sh" >/dev/null || fail "install under GROK_HOME exited non-zero"
[ -f "$GROK_HOME/hooks/clawee.json" ] || fail "install ignored GROK_HOME"
[ ! -e "$file" ] || fail "install wrote HOME/.grok with GROK_HOME set"
sh "$here/uninstall.sh" >/dev/null || fail "uninstall under GROK_HOME exited non-zero"
[ ! -e "$GROK_HOME/hooks/clawee.json" ] || fail "uninstall under GROK_HOME left the file"
echo "grok adapter: ok"
