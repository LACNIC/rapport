#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh
 
run_barry
start_rp
start_router
sleep 1 # TODO shouldn't be necessary
 
# Build the bundled query string based on N_QUERIES

N_QUERIES=5

BUNDLED=""
N_REP=0
while [ "$N_REP" -lt "$N_QUERIES" ]; do
    BUNDLED="${BUNDLED}reset-query\n"
    N_REP=$((N_REP + 1))
done

send_bundled_router_pdus "$BUNDLED"

check_logfile fort1 -F "Too many simultaneous requests; Dropping RTR connection"

check_pdus

stop_router
stop_rp
