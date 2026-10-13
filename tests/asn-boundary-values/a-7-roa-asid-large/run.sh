#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps \
	"1.1.0.0/24-24 => AS4200000000" \
	"1.1.1.0/24-24 => AS4200000000"	
check_aspas

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.1.0 as 4200000000" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 4200000000"

stop_router
stop_rp
