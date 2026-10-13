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

stop_router
stop_rp
