#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps
check_aspas "1:[2,3,4,5,65535]"

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers \[ 2 3 4 5 65535 \]"

stop_router
stop_rp
