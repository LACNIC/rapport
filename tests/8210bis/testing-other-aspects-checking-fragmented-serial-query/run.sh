#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003]"

send_router_pdu "reset-query"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 24 customer 1 providers [ 13001 13002 13003 ]"

create_delta rd2
revalidate_rp

# Sending serial-query serial 1
send_router_pdu "raw 0201 <session> 0000000c 00000001"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 28 customer 1 providers [ 13001 13002 13003 13004 ]"

# Sending fragmented serial-query serial 1
send_router_pdu "raw 0201 <session>"
send_router_pdu "sleep 100"
send_router_pdu "raw 0000000c"
send_router_pdu "sleep 100" 
send_router_pdu "raw 00000001"
check_cache_response 0 \
	"aspa-pdu       version 2 flags 1 zero 0 length 28 customer 1 providers [ 13001 13002 13003 13004 ]"

# Sending fragmented serial-query serial 1
send_router_pdu "raw 02 01 <session>"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 0c"
send_router_pdu "sleep 100" 
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 01"
check_cache_response 0 \
	"aspa-pdu       version 2 flags 1 zero 0 length 28 customer 1 providers [ 13001 13002 13003 13004 ]"

stop_router
stop_rp
