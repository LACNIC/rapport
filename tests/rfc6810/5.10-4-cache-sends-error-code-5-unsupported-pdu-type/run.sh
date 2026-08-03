#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps "1.1.0.0/24-24 => AS64512"

sleep 2


# Sending reset-query
send_router_pdu "raw 000c0000 00000008"

EXPECTED="error-report   version 0"
EXPECTED="$EXPECTED error-code 5"
EXPECTED="$EXPECTED length 24"
EXPECTED="$EXPECTED encapsulated-pdu-length [0-9]+"
EXPECTED="$EXPECTED encapsulated-pdu \[ unknown.*000c000000000008 \]"
EXPECTED="$EXPECTED error-text-length 0"

check_pdus "$EXPECTED"

stop_router
stop_rp