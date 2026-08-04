#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps \
	"1.1.0.0/24-24 => AS65536" \
	"1.1.1.0/24-24 => AS65536"	
check_aspas

send_router_pdu "reset-query"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.1.0 as 65536" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 65536" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

stop_router
stop_rp
