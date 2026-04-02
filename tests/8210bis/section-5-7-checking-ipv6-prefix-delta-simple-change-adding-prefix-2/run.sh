#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps \
		"100::/18-18 => AS65001" \
		"100:4000::/18-18 => AS65001"

check_aspas

send_router_pdu "reset-query"
check_cache_response 0 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 18 maxlen 18 zero2 0 prefix 100:4000:: as 65001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 18 maxlen 18 zero2 0 prefix 100:: as 65001"

create_delta rd2
revalidate_rp

check_vrps \
		"100::/18-18 => AS65001" \
		"100:4000::/18-18 => AS65001" \
		"100:8000::/18-18 => AS66001" \
		"100:c000::/18-18 => AS66001"

check_aspas

send_router_pdu "serial-query serial 1"

check_cache_response 1 \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 18 maxlen 18 zero2 0 prefix 100:8000:: as 66001" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 18 maxlen 18 zero2 0 prefix 100:c000:: as 66001"

stop_router
stop_rp
