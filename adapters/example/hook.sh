#!/bin/sh
sid="${CLAWEE_SID:-}"
[ -n "$sid" ] || exit 0
clawee="${CLAWEE_BIN:-clawee}"
command -v "$clawee" >/dev/null 2>&1 || exit 0
kind="${1:-question}"
shift 2>/dev/null || true
"$clawee" sessions signal "/$sid" "$kind" "$@" >/dev/null 2>&1 || true
exit 0
