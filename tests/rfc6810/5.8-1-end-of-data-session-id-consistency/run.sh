#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- Reset Query path
# ---------------------------------------------------------------------------


run_barry rd1
start_rp
start_router

check_vrps "1.1.0.0/24-24 => AS64512"

send_router_pdu "reset-query version 0"
check_cache_response_v0 0 1 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512"

RQ_CR_SESSION_ID=$(grep "^cache-response" "$SANDBOX/checks-pdu/actual.txt" \
    | grep -oE 'session [0-9]+' | grep -oE '[0-9]+')

RQ_EOD_SESSION_ID=$(grep "^end-of-data" "$SANDBOX/checks-pdu/actual.txt" \
    | grep -oE 'session [0-9]+' | grep -oE '[0-9]+')

test -n "$RQ_CR_SESSION_ID" || fail "Could not extract Session ID from Cache Response PDU"
test -n "$RQ_EOD_SESSION_ID" || fail "Could not extract Session ID from End of Data PDU"

ck_inc
if [ "$RQ_CR_SESSION_ID" != "$RQ_EOD_SESSION_ID" ]; then
    fail "Reset Query path: Session ID mismatch between Cache Response ($RQ_CR_SESSION_ID) and End of Data ($RQ_EOD_SESSION_ID)"
fi

# ---------------------------------------------------------------------------
# P1 -- Serial Query path
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513"

send_router_pdu "serial-query serial 1 version 0"

check_cache_response_v0 1 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513"

SQ_CR_SESSION_ID=$(grep "cache-response" "$SANDBOX/checks-pdu/actual.txt" \
    | grep -oE 'session [0-9]+' | grep -oE '[0-9]+')

SQ_EOD_SESSION_ID=$(grep "end-of-data" "$SANDBOX/checks-pdu/actual.txt" \
    | grep -oE 'session [0-9]+' | grep -oE '[0-9]+')

test -n "$SQ_CR_SESSION_ID" || fail "Could not extract Session ID from Cache Response PDU"
test -n "$SQ_EOD_SESSION_ID" || fail "Could not extract Session ID from End of Data PDU"

ck_inc
if [ "$SQ_CR_SESSION_ID" != "$SQ_EOD_SESSION_ID" ]; then
    fail "Reset Query path: Session ID mismatch between Cache Response ($SQ_CR_SESSION_ID) and End of Data ($SQ_EOD_SESSION_ID)"
fi

stop_router
stop_rp
