#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "2"
start_router

check_vrps
check_aspas "1:[11001]"

send_router_pdu "reset-query"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 1 providers \[ 11001 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

send_router_pdu "serial-query session 12345 serial 1"
check_error_report_pdu "fort1" "2" "0" \
	"serial-query   version 2 session 12345 length 12 serial 1" \
	"Session ID doesn't match."

stop_router
stop_rp
