#!/bin/sh
: "${FAKE_CLAWEE_LOG:?set FAKE_CLAWEE_LOG to the file to record argv into}"
printf '%s\n' "$*" >> "$FAKE_CLAWEE_LOG"
[ -z "${FAKE_CLAWEE_STDOUT:-}" ] || cat "$FAKE_CLAWEE_STDOUT"
exit "${FAKE_CLAWEE_EXIT:-0}"
