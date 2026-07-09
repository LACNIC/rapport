#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh
 
run_barry
start_rp
start_router
sleep 1 # TODO shouldn't be necessary
 

send_router_pdu "reset-query"
send_router_pdu "error-report   version 2 error-code 0 length 16 encapsulated-pdu-length 0 error-text-length 0"
send_router_pdu "reset-query"
 
# Only the first reset-query gets a response; Fort closes the connection
# after the error-report without answering it or the second reset-query.

check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 8 maxlen 8 zero2 0 prefix 3.0.0.0 as 1234" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 8 maxlen 8 zero2 0 prefix 2.0.0.0 as 1234" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 8 maxlen 8 zero2 0 prefix 1.0.0.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 8 maxlen 8 zero2 0 prefix 300:: as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 8 maxlen 8 zero2 0 prefix 200:: as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 8 maxlen 8 zero2 0 prefix 100:: as 1234" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 67108864 providers \[ 0 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 83886080 providers \[ 0 \]" \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 100663296 providers \[ 0 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

check_logfile fort1 -F "ERR: RTR client 127.0.0.1 responded with error PDU 'Corrupt Data'. Closing socket."

stop_router
stop_rp
 