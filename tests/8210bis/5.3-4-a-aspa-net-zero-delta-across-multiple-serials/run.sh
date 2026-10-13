#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp
start_router

check_vrps
check_aspas "16842752:[11001,11002,11003,11004,11005]"

send_router_pdu "reset-query"
check_cache_response 0 1 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16842752 providers \[ 11001 11002 11003 11004 11005 \]"


# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 2 "aspa-pdu       version 2 flags 0 zero 0 length 12 customer 16842752"

# Processing serial 3
new_step
create_delta rd3
revalidate_rp

check_vrps
check_aspas "16842752:[11001,11002,11003,11004,11005]" \

send_router_pdu "serial-query serial 1"
check_cache_response 1 3

stop_router
stop_rp
