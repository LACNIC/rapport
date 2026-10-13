#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- baseline: first validation cycle, initial exchange via Reset Query
# ---------------------------------------------------------------------------

run_barry rd1
start_rp
start_router

check_vrps \
	"1.1.0.0/24-24 => AS65001" \
	"1.2.0.0/24-24 => AS65002"

sleep 1

send_router_pdu "reset-query version 0"

check_cache_response_v0 0 1 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 65002" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 65001"

# ---------------------------------------------------------------------------
# P1 -- first update: advance serial to 2
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS65001" \
	"2.1.0.0/24-24 => AS65003"

send_router_pdu "serial-query serial 1 version 0"

check_cache_response_v0 1 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 2.1.0.0 as 65003" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 65002"

stop_router
stop_rp
