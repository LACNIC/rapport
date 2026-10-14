#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp "--server.deltas.lifetime" "4"
start_router

check_vrps \
	"1.1.0.0/24-24 => AS13001" \
	"1.1.1.0/24-24 => AS13001" \
	"1.1.2.0/24-24 => AS14001" \
	"1.1.3.0/24-24 => AS14001" \
	"1.1.4.0/24-24 => AS15001" \
	"1.1.5.0/24-24 => AS15001" \
	"1.1.6.0/24-24 => AS16001" \
	"1.1.7.0/24-24 => AS16001" \
	"1.1.8.0/24-24 => AS17001" \
	"1.1.9.0/24-24 => AS17001" 	

send_router_pdu "reset-query version 0"
check_cache_response_v0 0 1 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.1.0 as 13001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 13001"

# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS13001" \
	"1.1.1.0/24-24 => AS13001" \
	"1.1.2.0/24-24 => AS14001" \
	"1.1.3.0/24-24 => AS14001" \
	"1.1.4.0/24-24 => AS15001" \
	"1.1.5.0/24-24 => AS15001" \
	"1.1.6.0/24-24 => AS16001" \
	"1.1.7.0/24-24 => AS16001"	

send_router_pdu "serial-query serial 1 version 0"
check_cache_response_v0 1 2 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001"

# Processing serial 3
new_step
create_delta rd3
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS13001" \
	"1.1.1.0/24-24 => AS13001" \
	"1.1.2.0/24-24 => AS14001" \
	"1.1.3.0/24-24 => AS14001" \
	"1.1.4.0/24-24 => AS15001" \
	"1.1.5.0/24-24 => AS15001" 

send_router_pdu "serial-query serial 1 version 0"
check_cache_response_v0 1 3 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001"

send_router_pdu "serial-query serial 2 version 0"
check_cache_response_v0 0 3 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001"

# Processing serial 4
new_step
create_delta rd4
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS13001" \
	"1.1.1.0/24-24 => AS13001" \
	"1.1.2.0/24-24 => AS14001" \
	"1.1.3.0/24-24 => AS14001" 

send_router_pdu "serial-query serial 1 version 0"
check_cache_response_v0 1 4 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001"

send_router_pdu "serial-query serial 2 version 0"
check_cache_response_v0 0 4 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001"

send_router_pdu "serial-query serial 3 version 0"
check_cache_response_v0 0 4 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001"

# Processing serial 5
new_step
create_delta rd5
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS13001" \
	"1.1.1.0/24-24 => AS13001"

send_router_pdu "serial-query serial 1 version 0"
check_cache_response_v0 1 5 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001"

send_router_pdu "serial-query serial 2 version 0"
check_cache_response_v0 0 5 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001"

send_router_pdu "serial-query serial 3 version 0"
check_cache_response_v0 0 5 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001"

send_router_pdu "serial-query serial 4 version 0"
check_cache_response_v0 0 5 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001"

stop_router
stop_rp
