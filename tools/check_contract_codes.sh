#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
contract=${1:-CONTRACT.md}
want=$(printf '%s\n' done blocked.auth blocked.permission blocked.question error review gate answered | sort)
have=$(awk '/^\| code \| next step \|/{t=1;next} t&&/^\|---/{next} t&&/^\| `/{gsub(/`/,"",$2);print $2;next} t{t=0}' "$contract" | sort)
if [ "$want" = "$have" ]; then echo "ok   contract codes"; exit 0; fi
echo "FAIL contract codes differ"; printf 'want:\n%s\nhave:\n%s\n' "$want" "$have"; exit 1
