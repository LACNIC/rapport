#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "4"
start_router

check_vrps
check_aspas "16842752:[11001,11002,11003,11004,11005]"

send_router_pdu "reset-query"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16842752 providers \[ 11001 11002 11003 11004 11005 \]"

# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas \
	"16842752:[11001,11002,11003,11004,11005]" \
	"16908288:[22001,22002,22003,22004,22005]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16908288 providers \[ 22001 22002 22003 22004 22005 \]"

# Processing serial 3
new_step
create_delta rd3
revalidate_rp

check_vrps
check_aspas  \
	"16842752:[11001,11002,11003,11004,11005]" \
	"16908288:[22001,22002,22003,22004,22005]" \
	"16973824:[33001,33002,33003,33004,33005]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16908288 providers \[ 22001 22002 22003 22004 22005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16973824 providers \[ 33001 33002 33003 33004 33005 \]"

# Processing serial 4
new_step
create_delta rd4
revalidate_rp

check_vrps
check_aspas \
	"16842752:[11001,11002,11003,11004,11005]" \
	"16908288:[22001,22002,22003,22004,22005]" \
	"16973824:[33001,33002,33003,33004,33005]" \
	"17039360:[44001,44002,44003,44004,44005]" 

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16908288 providers \[ 22001 22002 22003 22004 22005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16973824 providers \[ 33001 33002 33003 33004 33005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 17039360 providers \[ 44001 44002 44003 44004 44005 \]"

# Processing serial 5
new_step
create_delta rd5
revalidate_rp

check_vrps
check_aspas \
	"16842752:[11001,11002,11003,11004,11005]" \
	"16908288:[22001,22002,22003,22004,22005]" \
	"16973824:[33001,33002,33003,33004,33005]" \
	"17039360:[44001,44002,44003,44004,44005]" \
	"17104896:[55001,55002,55003,55004,55005]"

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16908288 providers \[ 22001 22002 22003 22004 22005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16973824 providers \[ 33001 33002 33003 33004 33005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 17039360 providers \[ 44001 44002 44003 44004 44005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 17104896 providers \[ 55001 55002 55003 55004 55005 \]"

stop_router
stop_rp
