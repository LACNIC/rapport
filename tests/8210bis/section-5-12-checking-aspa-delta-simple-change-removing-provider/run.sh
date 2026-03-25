#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003,13004,13005]"

send_router_pdu "reset-query"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 13001 13002 13003 13004 13005 ]"

create_delta rd2
revalidate_rp

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 24 customer 1 providers [ 13001 13002 13003 ]"

stop_router
stop_rp
