#!/bin/sh
# fake-clawee.sh — stands in for the clawee cli in smoke tests. It records
# its argv, one invocation per line, to $FAKE_CLAWEE_LOG and exits 0. Put a
# directory holding this file (as `clawee`) first on PATH.
: "${FAKE_CLAWEE_LOG:?set FAKE_CLAWEE_LOG to the file to record argv into}"
printf '%s\n' "$*" >> "$FAKE_CLAWEE_LOG"
exit 0
