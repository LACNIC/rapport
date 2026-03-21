#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003]"

send_router_pdu "reset-query version 3"
check_error_report_pdu "fort1" "2" "4" \
	"reset-query    version 3 zero 0 length 8" \
	"The maximum supported RTR version is 2."

stop_router
stop_rp