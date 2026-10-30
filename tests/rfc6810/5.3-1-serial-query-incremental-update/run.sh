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

send_router_pdu "reset-query version 0"

check_cache_response_v0 0 1 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512"

# Extract Serial Number from the End of Data PDU.
P0_SERIAL=$(grep "^end-of-data" "$SANDBOX/checks-pdu/actual.txt" \
    | grep -oE 'serial [0-9]+' | grep -oE '[0-9]+')

test -n "$P0_SERIAL"  || fail "Could not extract Serial Number from End of Data PDU"


# ---------------------------------------------------------------------------
# P1 -- updated repository: second validation cycle, incremental update
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513"

send_router_pdu "serial-query serial $P0_SERIAL version 0"

check_cache_response_v0 1 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513"

# Verify the End of Data Serial Number is strictly greater than P0's,
P1_SERIAL=$(grep "^end-of-data" "$SANDBOX/checks-pdu/actual.txt" \
    | grep -oE 'serial [0-9]+' | grep -oE '[0-9]+')

test -n "$P1_SERIAL" || fail "Could not extract Serial Number from End of Data PDU"

ck_inc
if [ "$P1_SERIAL" -le "$P0_SERIAL" ]; then
    fail "End of Data serial ($P1_SERIAL) is not strictly greater than P0 serial ($P0_SERIAL)"
fi

stop_router
stop_rp
