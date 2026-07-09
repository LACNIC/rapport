#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh
 
run_barry
start_rp
start_router
sleep 1 # TODO shouldn't be necessary
 
# Send N_QUERIES reset-query PDUs as fast as possible, each in its own TCP
# packet. Fort closes the connection when queries > 4, so some send_router_pdu
# processes will find barry-rtr already gone and print "Server unreachable".
# 2>/dev/null suppresses that expected noise without masking test failures.
N_QUERIES=10
N_REP=0
while [ "$N_REP" -lt "$N_QUERIES" ]; do
    send_router_pdu "reset-query" 2>/dev/null &
    N_REP=$((N_REP + 1))
done

sleep 2

check_logfile fort1 -F "Too many simultaneous requests; Dropping RTR connection"

PDUS_PER_RESPONSE=11   # cache-response + 3 ipv4 + 3 ipv6 + 3 aspa + end-of-data
check_partial_responses "$PDUS_PER_RESPONSE" "$N_QUERIES"

# In theory, barry-rtr ends automatically when Fort drops the TCP connection.
# kill -0 checks whether the process still exists without sending a signal;
# if it is already gone, clear BARRY_RTR_PID so stop_router does not
# attempt to kill a non-existent process and print "No such process".
kill -0 "$BARRY_RTR_PID" 2>/dev/null || export BARRY_RTR_PID=""
stop_router
stop_rp
