#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "2"
start_router

check_vrps
check_aspas "16842752:[11001]"

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 16842752 providers \[ 11001 \]"

send_router_pdu "serial-query serial 1"
check_cache_response 0 1

# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas \
	"16842752:[11001]" \
	"16908288:[22001]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 2 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 16908288 providers \[ 22001 \]"

send_router_pdu "serial-query serial 2"
check_cache_response 0 2

stop_router
stop_rp
