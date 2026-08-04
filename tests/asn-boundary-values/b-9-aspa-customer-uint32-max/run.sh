#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps
check_aspas "4294967295:[1000,1001,1002]"

send_router_pdu "reset-query"
check_pdus \
        "cache-response version 2 session [0-9]+ length 8" \
        "aspa-pdu       version 2 flags 1 zero 0 length 24 customer 4294967295 providers \[ 1000 1001 1002 \]" \
        "end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

stop_router
stop_rp
