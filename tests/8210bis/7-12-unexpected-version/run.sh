#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "16842752:[13001,13002,13003]"

send_router_pdu "reset-query version 2"
check_cache_response 0 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 24 customer 16842752 providers \[ 13001 13002 13003 \]"

send_router_pdu "reset-query version 1"
check_error_report_pdu "fort2" "2" "8" \
	"reset-query    version 1 zero 0 length 8" \
	"The RTR version does not match the one we negotiated during the handshake."
check_logfile fort2 -F "ERR: 127.0.0.1: Client changed RTR version: 2 -> 1"

stop_router
stop_rp
