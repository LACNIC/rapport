#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp
start_router

check_vrps \
	"1.0.0.0/8-8 => AS1234" \
	"100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" \
	"200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" \
	"300::/8-8 => AS1234"
check_aspas \
	"100663296:[0]" \
	"67108864:[0]" \
	"83886080:[0]"

# Reset Query
send_router_pdu "reset-query"
check_cache_response 0 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 100663296 providers [ 0 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 67108864 providers [ 0 ]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 83886080 providers [ 0 ]" \
	"ipv4-prefix    version 2 zero 0 length 20 flags 1 plen 8 maxlen 8 zero 0 prefix 1.0.0.0 as 1234" \
	"ipv4-prefix    version 2 zero 0 length 20 flags 1 plen 8 maxlen 8 zero 0 prefix 2.0.0.0 as 1234" \
	"ipv4-prefix    version 2 zero 0 length 20 flags 1 plen 8 maxlen 8 zero 0 prefix 3.0.0.0 as 1234" \
	"ipv6-prefix    version 2 zero 0 length 32 flags 1 plen 8 maxlen 8 zero 0 prefix 100:: as 1234" \
	"ipv6-prefix    version 2 zero 0 length 32 flags 1 plen 8 maxlen 8 zero 0 prefix 200:: as 1234" \
	"ipv6-prefix    version 2 zero 0 length 32 flags 1 plen 8 maxlen 8 zero 0 prefix 300:: as 1234"

create_delta rd2
revalidate_rp


# Serial Query
send_router_pdu "serial-query serial 1"
check_cache_response 1 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 67108864 providers [ 0 ]" \
	"ipv4-prefix    version 2 zero 0 length 20 flags 0 plen 8 maxlen 8 zero 0 prefix 1.0.0.0 as 1234" \
	"ipv4-prefix    version 2 zero 0 length 20 flags 1 plen 8 maxlen 8 zero 0 prefix 1.0.0.0 as 4321" \
	"ipv6-prefix    version 2 zero 0 length 32 flags 0 plen 8 maxlen 8 zero 0 prefix 100:: as 1234" \
	"ipv6-prefix    version 2 zero 0 length 32 flags 1 plen 8 maxlen 8 zero 0 prefix 100:: as 4321"

#	"aspa-pdu       version 2 flags 0 zero 0 length 16 customer 83886080 providers [ 0 ]" \
#	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 83886080 providers [ 1 2 3 ]" \


# Cache Reset
send_router_pdu "serial-query serial 5"
check_pdus \
	"cache-reset    version 2 zero 0 length 8"


# Error Report
send_router_pdu "serial-query version 1 serial 1"
check_error_report_pdu "fort1" "2" "8" \
	"serial-query   version 1 session [0-9]+ length 12 serial 1" \
	"The RTR version does not match the one we negotiated during the handshake."


stop_router
stop_rp
