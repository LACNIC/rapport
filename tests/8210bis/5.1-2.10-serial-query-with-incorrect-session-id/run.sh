#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "2"
start_router

check_vrps
check_aspas "16842752:[11001]"

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 16842752 providers \[ 11001 \]"

send_router_pdu "serial-query session 12345 serial 1"
check_error_report_pdu "fort1" "2" "0" \
	"serial-query   version 2 session 12345 length 12 serial 1" \
	"Session ID doesn't match."

stop_router
stop_rp
