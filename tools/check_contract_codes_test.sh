#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
grep -v '^| `gate` |' CONTRACT.md > "$tmp"
if sh tools/check_contract_codes.sh "$tmp" >/dev/null; then echo "FAIL removed row not detected"; exit 1; fi
echo "ok   check fails on removed row"
