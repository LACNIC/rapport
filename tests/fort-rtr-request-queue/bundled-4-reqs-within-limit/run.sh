#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh
 
run_barry
start_rp
start_router
sleep 1 # TODO shouldn't be necessary
 
# Build the bundled query string based on N_QUERIES

N_QUERIES=4

BUNDLED=""
N_REP=0
while [ "$N_REP" -lt "$N_QUERIES" ]; do
    BUNDLED="${BUNDLED}reset-query\n"
    N_REP=$((N_REP + 1))
done
 
# Build the expected PDU sequence based on N_QUERIES
set --
N_REP=0
while [ "$N_REP" -lt "$N_QUERIES" ]; do
    set -- "$@" \
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
    N_REP=$((N_REP + 1))
done
 
send_bundled_router_pdus "$BUNDLED"
check_pdus "$@"
 
stop_router
stop_rp
