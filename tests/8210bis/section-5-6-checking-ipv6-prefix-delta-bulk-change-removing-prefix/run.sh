#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp "--server.deltas.lifetime" "4"
start_router

check_vrps \
		"100:1000::/20-20 => AS1000" \
		"100:2000::/20-20 => AS1000" \
		"100:3000::/20-20 => AS2000" \
		"100:4000::/20-20 => AS2000" \
		"100:5000::/20-20 => AS2000" \
		"100:6000::/20-20 => AS3000" \
		"100:7000::/20-20 => AS3000" \
		"100:8000::/20-20 => AS3000" \
		"100:9000::/20-20 => AS4000" \
		"100:a000::/20-20 => AS4000" \
		"100:b000::/20-20 => AS4000" \
		"100:c000::/20-20 => AS5000" \
		"100:d000::/20-20 => AS5000" \
		"100:e000::/20-20 => AS5000"

check_aspas

send_router_pdu "reset-query"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:1000:: as 1000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:2000:: as 1000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" 


# Processing serial 2
create_delta rd2
revalidate_rp

check_vrps \
		"100:1000::/20-20 => AS1000" \
		"100:2000::/20-20 => AS1000" \
		"100:3000::/20-20 => AS2000" \
		"100:4000::/20-20 => AS2000" \
		"100:5000::/20-20 => AS2000" \
		"100:6000::/20-20 => AS3000" \
		"100:7000::/20-20 => AS3000" \
		"100:8000::/20-20 => AS3000" \
		"100:9000::/20-20 => AS4000" \
		"100:a000::/20-20 => AS4000" \
		"100:b000::/20-20 => AS4000"
		
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" 


# Processing serial 3
create_delta rd3
revalidate_rp

check_vrps \
		"100:1000::/20-20 => AS1000" \
		"100:2000::/20-20 => AS1000" \
		"100:3000::/20-20 => AS2000" \
		"100:4000::/20-20 => AS2000" \
		"100:5000::/20-20 => AS2000" \
		"100:6000::/20-20 => AS3000" \
		"100:7000::/20-20 => AS3000" \
		"100:8000::/20-20 => AS3000"
		
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" 

send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000"

# Processing serial 4
create_delta rd4
revalidate_rp

check_vrps \
		"100:1000::/20-20 => AS1000" \
		"100:2000::/20-20 => AS1000" \
		"100:3000::/20-20 => AS2000" \
		"100:4000::/20-20 => AS2000" \
		"100:5000::/20-20 => AS2000"
		
check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" 

send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000"

send_router_pdu "serial-query serial 3"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000"

# Processing serial 5
create_delta rd5
revalidate_rp

check_vrps \
		"100:1000::/20-20 => AS1000" \
		"100:2000::/20-20 => AS1000" 

check_aspas

send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" 

send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000"

send_router_pdu "serial-query serial 3"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000"

send_router_pdu "serial-query serial 4"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000"

stop_router
stop_rp
