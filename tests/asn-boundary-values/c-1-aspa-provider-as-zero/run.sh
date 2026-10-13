#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps
check_aspas "65535:[0]"

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 65535 providers \[ 0 \]"

stop_router
stop_rp
