#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- baseline: first validation cycle, initial exchange via Reset Query
# ---------------------------------------------------------------------------

run_barry rd1
start_rp
start_router

check_vrps "1.1.0.0/24-24 => AS64512"

sleep 2

send_router_pdu "reset-query version 0"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial [0-9]+"

# Extract Session ID and Serial Number from the End of Data PDU.
SESSION_ID=$(grep -a "^end-of-data" "$SANDBOX/pdu/actual.txt" \
    | grep -oE 'session [0-9]+' | grep -oE '[0-9]+')

test -n "$SESSION_ID" || fail "Could not extract Session ID from End of Data PDU"

# ---------------------------------------------------------------------------
# T1 -- Serial Query with wrong Session ID: cache must drop the session
# ---------------------------------------------------------------------------

WRONG_SESSION_ID=$(( (SESSION_ID + 1) % 65536 ))

send_router_pdu "serial-query session $WRONG_SESSION_ID serial 1 version 0"

check_error_report_pdu "fort1" "0" "0" \
	"serial-query   version 0 session $WRONG_SESSION_ID length 12 serial 1" \
	"Session ID doesn't match."

stop_router
stop_rp
