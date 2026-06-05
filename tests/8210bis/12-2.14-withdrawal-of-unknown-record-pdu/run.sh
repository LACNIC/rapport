#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps
check_aspas "1:[13001,13002,13003,13004,13005]"

# Sending reset-query
send_router_pdu "reset-query"
check_pdus \
	"cache-response version 2 session [0-9]+ length 8" \
	"aspa-pdu       version 2 flags 1 zero 0 length 32 customer 1 providers \[ 13001 13002 13003 13004 13005 \]" \
	"end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"

# Simulating that the router sends error code 6 [Withdrawal of Unknown Record] to the server.
send_router_pdu "error-report   version 2 error-code 6 length 16 encapsulated-pdu-length 0 error-text-length 0"

check_logfile fort1 -F "ERR: RTR client 127.0.0.1 responded with error PDU 'Withdrawal of Unknown Record'. Closing socket."

# Checking connection is closed.
send_router_pdu "reset-query"
check_pdus

stop_router
stop_rp
