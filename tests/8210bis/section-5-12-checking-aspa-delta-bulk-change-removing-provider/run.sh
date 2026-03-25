#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "4"
start_router

check_vrps
check_aspas "1:[13001,13002,13003,13004,13005]"

send_router_pdu "reset-query"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 13001 13002 13003 13004 13005 ]"

# Processing serial 2
create_delta rd2
revalidate_rp

check_vrps
check_aspas "1:[13002,13003,13004,13005]"

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 28 customer 1 providers [ 13002 13003 13004 13005 ]"

# Processing serial 3
create_delta rd3
revalidate_rp

check_vrps
check_aspas "1:[13003,13004,13005]"

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 24 customer 1 providers [ 13003 13004 13005 ]"


# Processing serial 4
create_delta rd4
revalidate_rp

check_vrps
check_aspas "1:[13004,13005]"

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 20 customer 1 providers [ 13004 13005 ]"

# Processing serial 5
create_delta rd5
revalidate_rp

check_vrps
check_aspas "1:[13005]"

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 1 providers [ 13005 ]"

stop_router
stop_rp
