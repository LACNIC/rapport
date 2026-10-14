#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps "1.1.0.0/24-24 => AS64512"

send_router_pdu "reset-query version 0"

check_cache_response_v0 0 1 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512"

new_step
create_delta rd2
revalidate_rp

# Sending serial-query serial 1
send_router_pdu "raw 0001 <session> 0000000c 00000001"
check_cache_response_v0 1 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513"

# Sending fragmented serial-query serial 1
send_router_pdu "raw 0001 <session>"
send_router_pdu "sleep 100"
send_router_pdu "raw 0000000c"
send_router_pdu "sleep 100" 
send_router_pdu "raw 00000001"
check_cache_response_v0 0 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513"

# Sending fragmented serial-query serial 1
send_router_pdu "raw 00 01 <session>"
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
check_cache_response_v0 0 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513"

stop_router
stop_rp
