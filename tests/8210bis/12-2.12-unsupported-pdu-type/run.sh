#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003,13004,13005]"

# Sending reset-query
send_router_pdu "raw 020c0000 00000008"

check_pdus \
	"error-report   version 2 error-code 5 length 24 encapsulated-pdu-length [0-9]+ encapsulated-pdu \[ unknown.*020c000000000008 \] error-text-length 0"

stop_router
stop_rp
