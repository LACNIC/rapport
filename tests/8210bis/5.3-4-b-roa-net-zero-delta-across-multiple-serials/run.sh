#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp
start_router

check_vrps \
	"101::/16-16 => AS1234"	\
	"1.1.0.0/16-16 => AS1234"	
check_aspas

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 101:: as 1234"

# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 2 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 16 maxlen 16 zero2 0 prefix 101:: as 1234"

# Processing serial 3
new_step
create_delta rd3
revalidate_rp

check_vrps \
	"101::/16-16 => AS1234"	\
	"1.1.0.0/16-16 => AS1234"	
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 3

stop_router
stop_rp
