#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh
 
run_barry
start_rp
start_router
sleep 1 # TODO shouldn't be necessary
 

# Send N_QUERIES reset-query PDUs as fast as possible, each in its own TCP
# packet.

N_QUERIES=4

N_REP=0
while [ "$N_REP" -lt "$N_QUERIES" ]; do
    send_router_pdu "reset-query" &
    N_REP=$((N_REP + 1))
done

sleep 2

# Build the expected PDU sequence: N_QUERIES full response blocks.
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
 
check_pdus "$@"
 
stop_router
stop_rp
 