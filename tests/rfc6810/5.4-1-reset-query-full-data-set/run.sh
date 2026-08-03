#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- baseline: first validation cycle, initial exchange via Reset Query
# ---------------------------------------------------------------------------

run_barry rd1
start_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512"

# ---------------------------------------------------------------------------
# P1 -- first update: advance serial to 2
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513"

# ---------------------------------------------------------------------------
# P2 -- second update: advance serial to 3
# ---------------------------------------------------------------------------

new_step
create_delta rd3
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513" \
	"1.3.0.0/24-24 => AS64514"

# ---------------------------------------------------------------------------
# P3 -- third update: advance serial to 4
# ---------------------------------------------------------------------------

new_step
create_delta rd4
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513" \
	"1.3.0.0/24-24 => AS64514" \
	"1.4.0.0/24-24 => AS64515"

# ---------------------------------------------------------------------------
# P4 -- fourth update: advance serial to 5
# ---------------------------------------------------------------------------

new_step
create_delta rd5
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513" \
	"1.3.0.0/24-24 => AS64514" \
	"1.4.0.0/24-24 => AS64515" \
	"1.5.0.0/24-24 => AS64516"


# Router establishes connection with the RTR Server and immediately sends the reset query.
start_router

sleep 2

send_router_pdu "reset-query version 0"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.5.0.0 as 64516" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.4.0.0 as 64515" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.3.0.0 as 64514" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial [0-9]+"

stop_router
stop_rp
