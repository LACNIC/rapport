#!/bin/sh

. tools/checks.sh
. rp/$RP.sh



tools/rsyncd-stop.sh "1"
sleep 1

run_barry

rm -f sandbox/apache2/content/$TEST/*

rm "sandbox/rsyncd/content/$TEST/ca/aspa.asa"
truncate -s 1m "sandbox/rsyncd/content/$TEST/ca/aspa.asa"
$RSYNC --daemon --bwlimit=1 --config="sandbox/rsyncd/rsyncd.conf"

# After a new instance of rsync is started with a specific configuration for this test, 
# rsync must be stopped and then started again with the shared configuration for the 
# rest of the tests. It doesn't matter if the script completes successfully or fails.
trap '
	sleep 5
	tools/rsyncd-stop.sh "1"
	sleep 2
	tools/rsyncd-start.sh "1"
' EXIT

rp_start
export RP_PID="$!"
wait_rp_output "INF: [127.0.0.1]:8323: Success."

start_router

sleep 0.2

send_router_pdu "reset-query"
check_pdus \
	"error-report   version 2 error-code 2 length [0-9]+ encapsulated-pdu-length 0 error-text-length 0"

stop_rp
stop_router
