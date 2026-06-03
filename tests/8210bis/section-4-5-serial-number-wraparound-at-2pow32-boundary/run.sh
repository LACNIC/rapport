#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspas "1:[13001,13002,13003]"

# TODO: The case of each validator must be analyzed.
# We override the serial number of FORT
sed -Ei"" \
    's/serial:[0-9]+ /serial:4294967294 /g' \
    "sandbox/tests/8210bis/$TEST/latest/workdir/rtr/index"

# We execute the validation waiting for the serial 4294967295 
run_barry rd
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003]"

send_router_pdu "reset-query"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 24 customer 1 providers \[ 13001 13002 13003 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 4294967295 refresh [0-9]+ retry [0-9]+ expire [0-9]+"
 
# We execute another validation waiting for the serial 0
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas "1:[13001,13002,13003,13004]"

send_router_pdu "reset-query"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 0" \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 28 customer 1 providers \[ 13001 13002 13003 13004 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 0 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# We execute another validation waiting for the serial 1
new_step
create_delta rd3
revalidate_rp

check_vrps
check_aspas \
	"1:[13001,13002,13003,13004,13005]" \
	"2:[2001]"

send_router_pdu "reset-query"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 1" \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers \[ 13001 13002 13003 13004 13005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 2 providers \[ 2001 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

send_router_pdu "serial-query serial 4294967295"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers \[ 13001 13002 13003 13004 13005 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 2 providers \[ 2001 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

stop_router
stop_rp

