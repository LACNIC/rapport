#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp
start_router

check_vrps \
	"201::/16-16 => AS1234"	\
	"2.1.0.0/16-16 => AS1234"	
check_aspas

send_router_pdu "reset-query"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 2.1.0.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 16 maxlen 16 zero2 0 prefix 201:: as 1234" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps
check_aspas

send_router_pdu "serial-query serial 1"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 2" \
	"cache-response version 2 session [0-9]+ length 8" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 16 zero2 0 prefix 2.1.0.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 16 maxlen 16 zero2 0 prefix 201:: as 1234" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 2 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# Processing serial 3
new_step
create_delta rd3
revalidate_rp

check_vrps \
	"201::/16-16 => AS1234"	\
	"2.1.0.0/16-16 => AS1234"	
check_aspas

send_router_pdu "serial-query serial 1"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 3" \
	"cache-response version 2 session [0-9]+ length 8" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 3 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

stop_router
stop_rp
