#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
start_rp
start_router

check_vrps "1.1.0.0/24-24 => AS64512"

sleep 2

# Sending reset-query
send_router_pdu "raw 00020000 00000008"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

# Sending fragmented reset-query
send_router_pdu "raw 00020000"
send_router_pdu "sleep 100"
send_router_pdu "raw 00000008"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

# Sending fragmented reset-query
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 02"
send_router_pdu "sleep 100"
send_router_pdu "raw 0000"
send_router_pdu "sleep 100"
send_router_pdu "raw 00000008"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

# Sending fragmented reset-query
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 02"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 00"
send_router_pdu "sleep 100"
send_router_pdu "raw 08"

check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

stop_router
stop_rp
