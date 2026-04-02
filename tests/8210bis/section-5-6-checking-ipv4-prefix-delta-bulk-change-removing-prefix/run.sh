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
		
check_aspas

send_router_pdu "reset-query"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 13001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.1.0 as 13001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001"


# Processing serial 2
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
		
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001" 

# Processing serial 3
create_delta rd3
revalidate_rp

check_vrps \
		"1.1.0.0/24-24 => AS13001" \
		"1.1.1.0/24-24 => AS13001" \
		"1.1.2.0/24-24 => AS14001" \
		"1.1.3.0/24-24 => AS14001" \
		"1.1.4.0/24-24 => AS15001" \
		"1.1.5.0/24-24 => AS15001" 

check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001" 


send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" 

# Processing serial 4
create_delta rd4
revalidate_rp

check_vrps \
		"1.1.0.0/24-24 => AS13001" \
		"1.1.1.0/24-24 => AS13001" \
		"1.1.2.0/24-24 => AS14001" \
		"1.1.3.0/24-24 => AS14001" 

check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001" 


send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" 

send_router_pdu "serial-query serial 3"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001"

# Processing serial 5
create_delta rd5
revalidate_rp

check_vrps \
		"1.1.0.0/24-24 => AS13001" \
		"1.1.1.0/24-24 => AS13001"

check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.8.0 as 17001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.9.0 as 17001" 


send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 16001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.7.0 as 16001" 

send_router_pdu "serial-query serial 3"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 15001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.5.0 as 15001"

send_router_pdu "serial-query serial 4"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.2.0 as 14001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 14001"

stop_router
stop_rp
