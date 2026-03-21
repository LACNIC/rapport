#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003]"

send_router_pdu "reset-query version 1"

check_pdus \
	"cache-response version 1 session [0-9]+ length 8" \
	"end-of-data    version 1 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

stop_router
stop_rp
