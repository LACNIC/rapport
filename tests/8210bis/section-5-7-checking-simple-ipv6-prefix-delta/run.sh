#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps \
		"101::/16-16 => AS13001"

check_aspas

send_router_pdu "reset-query"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero 0 length 32 flags 1 plen 16 maxlen 16 zero 0 prefix 101:: as 13001"

create_delta rd2
revalidate_rp

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"ipv6-prefix    version 2 zero 0 length 32 flags 0 plen 16 maxlen 16 zero 0 prefix 101:: as 13001" \
	"ipv6-prefix    version 2 zero 0 length 32 flags 1 plen 16 maxlen 16 zero 0 prefix 101:: as 13002" 

stop_router
stop_rp
