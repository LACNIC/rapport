#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Processing serial 1
run_barry rd1
start_rp "--server.deltas.lifetime" "2"
start_router

check_vrps
check_aspas "1:[11001]"

send_router_pdu "reset-query"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 1 providers \[ 11001 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# Processing serial 2
create_delta rd2
revalidate_rp

send_router_pdu "serial-query serial 1"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 2" \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 2 providers \[ 22001 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 2 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# Processing serial 3
create_delta rd3
revalidate_rp

send_router_pdu "serial-query serial 1"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 3" \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 3 providers \[ 33001 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 2 providers \[ 22001 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 3 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# Processing serial 4
create_delta rd4
revalidate_rp

send_router_pdu "serial-query serial 1"
check_pdus \
	"serial-notify  version 2 session [0-9]+ length 12 serial 4" \
	"cache-reset    version 2 zero 0 length 8" \

stop_router
stop_rp
