#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps \
		"1.1.0.0/24-24 => AS13001"		
check_aspas

send_router_pdu "reset-query"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 13001"
	

create_delta rd2
revalidate_rp

check_vrps \
		"1.1.0.0/24-24 => AS13001" \
		"1.1.1.0/24-24 => AS13001"	

check_aspas

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.1.0 as 13001" 

stop_router
stop_rp
