#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003]"

send_router_pdu "reset-query version 0"

check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

stop_router
stop_rp
