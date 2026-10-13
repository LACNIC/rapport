#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps
check_aspas

send_router_pdu "reset-query"
check_cache_response 0 1

stop_router
stop_rp
