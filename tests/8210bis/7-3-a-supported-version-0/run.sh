#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "16842752:[13001,13002,13003]"

send_router_pdu "reset-query version 0"
check_cache_response_v0 0 1

stop_router
stop_rp
