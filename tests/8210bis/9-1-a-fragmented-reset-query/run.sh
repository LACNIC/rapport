#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003,13004,13005]"

# Sending reset-query
send_router_pdu "raw 02020000 00000008"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 13001 13002 13003 13004 13005 ]"

# Sending fragmented reset-query
send_router_pdu "raw 02020000"
send_router_pdu "sleep 100"
send_router_pdu "raw 00000008"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 13001 13002 13003 13004 13005 ]"

# Sending fragmented reset-query
send_router_pdu "raw 02"
send_router_pdu "sleep 100"
send_router_pdu "raw 02"
send_router_pdu "sleep 100"
send_router_pdu "raw 0000"
send_router_pdu "sleep 100"
send_router_pdu "raw 00000008"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 13001 13002 13003 13004 13005 ]"

# Sending fragmented reset-query
send_router_pdu "raw 02"
send_router_pdu "sleep 100"
send_router_pdu "raw 02"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 08"
check_cache_response 0 "aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers [ 13001 13002 13003 13004 13005 ]"


stop_router
stop_rp
