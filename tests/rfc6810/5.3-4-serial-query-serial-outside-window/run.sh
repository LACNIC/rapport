#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- baseline: first validation cycle, initial exchange via Reset Query
# ---------------------------------------------------------------------------

run_barry rd1
start_rp "--server.deltas.lifetime" "2"
start_router

check_vrps \
	"1.1.0.0/24-24 => AS64512"

# TODO: remove sleep
sleep 2

send_router_pdu "reset-query version 0"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

# ---------------------------------------------------------------------------
# P1 -- first update: advance serial to 2
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513"

send_router_pdu "serial-query serial 1 version 0"

check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 2" \
    	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 2"

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

send_router_pdu "serial-query serial 1 version 0"

check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 3" \
    	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.3.0.0 as 64514" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 3"

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

send_router_pdu "serial-query serial 1 version 0"

check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 4" \
    	"cache-reset    version 0 (reserved|zero) 0 length 8"

stop_router
stop_rp
