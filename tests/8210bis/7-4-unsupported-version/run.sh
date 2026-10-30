#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "16842752:[13001,13002,13003]"

send_router_pdu "reset-query version 3"
check_error_report_pdu "fort2" "2" "4" \
	"reset-query    version 3 zero 0 length 8" \
	"RTR version number is too high."
check_logfile fort2 -F "ERR: 127.0.0.1: Unsupported RTR version: 3"

stop_router
stop_rp
