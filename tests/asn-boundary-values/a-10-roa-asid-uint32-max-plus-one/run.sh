#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_logfile fort2 -F "TRE: AS value (4294967296) is out of range."

check_vrps
check_aspas

send_router_pdu "reset-query"
check_cache_response 0 1

stop_router
stop_rp
