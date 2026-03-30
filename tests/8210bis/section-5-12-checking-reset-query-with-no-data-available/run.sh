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


rp_start
export RP_PID="$!"

sleep 0.2

start_router

sleep 0.2

send_router_pdu "reset-query"
check_error_report_pdu "fort1" "2" "2"
	"reset-query   version 2 length 12" \
	"No data available"


stop_rp
stop_router