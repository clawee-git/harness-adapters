#!/bin/sh
: "${FAKE_CLAWEE_LOG:?set FAKE_CLAWEE_LOG to the file to record argv into}"
printf '%s\n' "$*" >> "$FAKE_CLAWEE_LOG"
exit 0
