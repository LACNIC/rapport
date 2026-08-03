#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- baseline: first validation cycle, initial exchange
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
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"


SESSION_ID=$(grep -a "^end-of-data" "$SANDBOX/pdu/actual.txt" \
    | grep -oE 'session [0-9]+' | grep -oE '[0-9]+')

test -n "$SESSION_ID" || fail "Could not extract Session ID from End of Data PDU"


# ---------------------------------------------------------------------------
# P1 -- updated repository: second validation cycle
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513"

send_router_pdu "serial-query session $SESSION_ID serial 1 version 0"

check_pdus \
	"serial-notify  version 0 session $SESSION_ID length 12 serial 2" \
	"cache-response version 0 session $SESSION_ID length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
    	"end-of-data    version 0 session $SESSION_ID length 12 serial 2"

stop_router
stop_rp
