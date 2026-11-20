#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"
start_rp
start_router

send_router_pdu "reset-query"
check_cache_response 0 1 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 192.0.2.0 as 2" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 48 maxlen 48 zero2 0 prefix 2001:db8:1:: as 2"

# Step 2

new_step
create_delta "rd2"
revalidate_rp

send_router_pdu "reset-query"
check_cache_response 1 2 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 198.51.100.0 as 1" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 192.0.2.0 as 2" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 48 maxlen 48 zero2 0 prefix 2001:db8:2:: as 1" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 48 maxlen 48 zero2 0 prefix 2001:db8:1:: as 2"
send_router_pdu "serial-query serial 1"
check_cache_response 0 2 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 198.51.100.0 as 1" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 48 maxlen 48 zero2 0 prefix 2001:db8:2:: as 1"

# Step 3

new_step
create_delta "rd3"
revalidate_rp

send_router_pdu "reset-query"
check_cache_response 1 3 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 192.0.2.0 as 2" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 48 maxlen 48 zero2 0 prefix 2001:db8:1:: as 2"
send_router_pdu "serial-query serial 1"
check_cache_response 0 3
send_router_pdu "serial-query serial 2"
check_cache_response 0 3 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 198.51.100.0 as 1" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 48 maxlen 48 zero2 0 prefix 2001:db8:2:: as 1"

stop_router
stop_rp
