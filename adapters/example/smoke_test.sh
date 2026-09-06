#!/bin/sh
# smoke_test.sh — template: the hook sends exactly the expected argv.
set -eu
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin" && cp "$root/tools/fake-clawee.sh" "$tmp/bin/clawee" && chmod +x "$tmp/bin/clawee"
export PATH="$tmp/bin:$PATH" FAKE_CLAWEE_LOG="$tmp/argv.log" CLAWEE_SID=0123456789abcdef0123456789abcdef
: > "$FAKE_CLAWEE_LOG"
sh "$here/hook.sh" question "what next?"
[ "$(cat "$FAKE_CLAWEE_LOG")" = "sessions signal /$CLAWEE_SID question what next?" ] || { cat "$FAKE_CLAWEE_LOG" >&2; echo "FAIL: argv mismatch" >&2; exit 1; }
echo "example adapter: ok"
