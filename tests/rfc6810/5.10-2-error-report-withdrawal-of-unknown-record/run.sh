#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps \
	"1.1.0.0/24-24 => AS64512"

# Sending reset-query
send_router_pdu "reset-query version 0"
check_cache_response_v0 0 1 \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \

# Simulating that the router sends error code 6 [Withdrawal of Unknown Record] to the server.
send_router_pdu "error-report   version 0 error-code 6 length 16 encapsulated-pdu-length 0 error-text-length 0"
check_pdus

check_logfile fort1 -F "ERR: RTR client 127.0.0.1 responded with error PDU 'Withdrawal of Unknown Record'. Closing socket."

stop_router
stop_rp
