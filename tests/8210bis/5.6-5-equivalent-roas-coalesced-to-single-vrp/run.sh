#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_aspas
check_vrps \
	"101::/16-16 => AS10001" \
	"102::/16-16 => AS10001" \
	"103::/16-16 => AS10001" \
	"1.1.0.0/16-16 => AS10001" \
	"1.2.0.0/16-16 => AS10001" \
	"1.3.0.0/16-16 => AS10001"
	

send_router_pdu "reset-query"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.3.0.0 as 10001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 103:: as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 102:: as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 101:: as 10001"

new_step
create_delta rd2
revalidate_rp

check_aspas
check_vrps \
	"101::/16-16 => AS10001" \
	"102::/16-16 => AS10001" \
	"1.1.0.0/16-16 => AS10001" \
	"1.3.0.0/16-16 => AS10001"


send_router_pdu "reset-query"
check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.3.0.0 as 10001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 102:: as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 101:: as 10001"

send_router_pdu "serial-query serial 1"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 16 maxlen 16 zero2 0 prefix 103:: as 10001"

new_step
create_delta rd3
revalidate_rp

check_aspas
check_vrps \
	"101::/16-16 => AS10001" \
	"102::/16-16 => AS10001" \
	"103::/16-16 => AS10001" \
	"1.1.0.0/16-16 => AS10001" \
	"1.2.0.0/16-16 => AS10001" \
	"1.3.0.0/16-16 => AS10001"

send_router_pdu "reset-query"
check_cache_response 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.3.0.0 as 10001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.1.0.0 as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 103:: as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 102:: as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 101:: as 10001"

send_router_pdu "serial-query serial 1"
check_cache_response 0 

send_router_pdu "serial-query serial 2"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 1.2.0.0 as 10001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 103:: as 10001"

stop_router
stop_rp
