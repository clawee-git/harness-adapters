#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
status=0
for t in adapters/*/smoke_test.sh; do
  printf '== %s\n' "$t"
  if sh "$t"; then printf 'ok   %s\n' "$t"; else printf 'FAIL %s\n' "$t"; status=1; fi
done
for c in tools/check_contract_codes.sh tools/check_contract_codes_test.sh; do
  if sh "$c"; then :; else printf 'FAIL %s\n' "$c"; status=1; fi
done
exit $status
