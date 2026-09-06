#!/bin/sh
# run-tests.sh — every adapter's smoke test, in turn. Exit non-zero on the
# first failure. This is the reviewer's gate; there is no CI workflow.
set -eu
cd "$(dirname "$0")/.."
status=0
for t in adapters/*/smoke_test.sh; do
  printf '== %s\n' "$t"
  if sh "$t"; then printf 'ok   %s\n' "$t"; else printf 'FAIL %s\n' "$t"; status=1; fi
done
exit $status
