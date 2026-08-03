#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# P0 -- baseline: first validation cycle, initial exchange
# ---------------------------------------------------------------------------

run_barry rd1
start_rp
start_router

check_vrps \
	"1.1.0.0/16-16 => AS10001" \
	"1.2.0.0/16-16 => AS10001" \
	"1.3.0.0/16-16 => AS10001"

sleep 1

send_router_pdu "reset-query version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.3.0.0 as 10001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 10001" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

# ---------------------------------------------------------------------------
# P1 -- updated repository: second validation cycle 
# ---------------------------------------------------------------------------

new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/16-16 => AS10001" \
	"1.3.0.0/16-16 => AS10001"

send_router_pdu "reset-query version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 2" \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.3.0.0 as 10001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 10001" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 2"

send_router_pdu "serial-query serial 1 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 2"

# ---------------------------------------------------------------------------
# P2 -- updated repository: third validation cycle 
# ---------------------------------------------------------------------------

new_step
create_delta rd3
revalidate_rp

check_vrps \
	"1.1.0.0/16-16 => AS10001" \
	"1.2.0.0/16-16 => AS10001" \
	"1.3.0.0/16-16 => AS10001"

send_router_pdu "reset-query version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 3" \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.3.0.0 as 10001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 10001" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 3"

send_router_pdu "serial-query serial 1 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 3"

send_router_pdu "serial-query serial 2 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 3"

stop_router
stop_rp
