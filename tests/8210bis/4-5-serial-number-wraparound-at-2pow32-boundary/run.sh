#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspas "16842752:[13001,13002,13003]"

# TODO: The case of each validator must be analyzed.
# We override the serial number of FORT
sed -Ei"" \
    's/serial:[0-9]+ /serial:4294967294 /g' \
    "$SANDBOX/workdir/rtr/index"
mv "$SANDBOX/workdir/rtr/1" "$SANDBOX/workdir/rtr/4294967294"

# We execute the validation waiting for the serial 4294967295 
run_barry rd
start_rp
start_router

check_vrps
check_aspas "16842752:[13001,13002,13003]"

send_router_pdu "reset-query"
check_cache_response 0 4294967295 \
	"aspa-pdu       version 2 flags 1 zero 0 length 24 customer 16842752 providers \[ 13001 13002 13003 \]"
 
# We execute another validation waiting for the serial 0
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas "16842752:[13001,13002,13003,13004]"

send_router_pdu "reset-query"
check_cache_response 1 0 \
	"aspa-pdu       version 2 flags 1 zero 0 length 28 customer 16842752 providers \[ 13001 13002 13003 13004 \]"

# We execute another validation waiting for the serial 1
new_step
create_delta rd3
revalidate_rp

check_vrps
check_aspas \
	"16842752:[13001,13002,13003,13004,13005]" \
	"16908288:[2001]"

send_router_pdu "reset-query"
check_cache_response 1 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16842752 providers \[ 13001 13002 13003 13004 13005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 16908288 providers \[ 2001 \]"

send_router_pdu "serial-query serial 4294967295"
check_cache_response 0 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 16842752 providers \[ 13001 13002 13003 13004 13005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 16908288 providers \[ 2001 \]"

stop_router
stop_rp
