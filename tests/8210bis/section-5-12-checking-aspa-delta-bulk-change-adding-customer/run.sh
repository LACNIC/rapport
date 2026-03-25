#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "4"
start_router

check_vrps
check_aspas "1:[11001,11002,11003,11004,11005]"

send_router_pdu "reset-query"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 11001 11002 11003 11004 11005 ]"

# Processing serial 2
create_delta rd2
revalidate_rp

check_vrps
check_aspas "1:[11001,11002,11003,11004,11005]" \
			"2:[22001,22002,22003,22004,22005]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 2 providers [ 22001 22002 22003 22004 22005 ]"

# Processing serial 3
create_delta rd3
revalidate_rp

check_vrps
check_aspas "1:[11001,11002,11003,11004,11005]" \
			"2:[22001,22002,22003,22004,22005]" \
			"3:[33001,33002,33003,33004,33005]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 2 providers [ 22001 22002 22003 22004 22005 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 3 providers [ 33001 33002 33003 33004 33005 ]"


# Processing serial 4
create_delta rd4
revalidate_rp

check_vrps
check_aspas "1:[11001,11002,11003,11004,11005]" \
			"2:[22001,22002,22003,22004,22005]" \
			"3:[33001,33002,33003,33004,33005]" \
			"4:[44001,44002,44003,44004,44005]" 


send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 2 providers [ 22001 22002 22003 22004 22005 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 3 providers [ 33001 33002 33003 33004 33005 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 4 providers [ 44001 44002 44003 44004 44005 ]"

# Processing serial 5
create_delta rd5
revalidate_rp

check_vrps
check_aspas "1:[11001,11002,11003,11004,11005]" \
			"2:[22001,22002,22003,22004,22005]" \
			"3:[33001,33002,33003,33004,33005]" \
			"4:[44001,44002,44003,44004,44005]" \
			"5:[55001,55002,55003,55004,55005]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 2 providers [ 22001 22002 22003 22004 22005 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 3 providers [ 33001 33002 33003 33004 33005 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 4 providers [ 44001 44002 44003 44004 44005 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 5 providers [ 55001 55002 55003 55004 55005 ]"

stop_router
stop_rp
