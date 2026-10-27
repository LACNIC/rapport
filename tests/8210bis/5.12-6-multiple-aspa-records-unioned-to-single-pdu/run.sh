#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_logfile fort2 -F "TRC: Adding ASPA for customer 16842752"
check_logfile fort2 -F "TRC: Adding ASPA for customer 16842752"
check_logfile fort2 -F "TRC: Adding ASPA for customer 16908288"

check_vrps
check_aspas \
    "16842752:[10001,10002,10003]" \
    "16908288:[20001,20002]"

send_router_pdu "reset-query"
check_cache_response 0 1 \
    "aspa-pdu       version 2 flags 1 zero 0 length 24 customer 16842752 providers \[ 10001 10002 10003 \]" \
    "aspa-pdu       version 2 flags 1 zero 0 length 20 customer 16908288 providers \[ 20001 20002 \]"

new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas \
    "16842752:[10001,10002,10004]" \
    "16908288:[20001,20002]"

send_router_pdu "reset-query"
check_cache_response 1 2 \
    "aspa-pdu       version 2 flags 1 zero 0 length 24 customer 16842752 providers \[ 10001 10002 10004 \]" \
    "aspa-pdu       version 2 flags 1 zero 0 length 20 customer 16908288 providers \[ 20001 20002 \]"

send_router_pdu "serial-query serial 1"
check_cache_response 0 2 \
    "aspa-pdu       version 2 flags 1 zero 0 length 24 customer 16842752 providers \[ 10001 10002 10004 \]"

stop_router
stop_rp
