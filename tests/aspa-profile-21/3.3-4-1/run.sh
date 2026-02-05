#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspa_output "16777216:[16777215,16777217]"

check_logfile fort1 -F "good.asa: Adding ASPA for customer 16777216"
check_logfile fort1 -F "bad.asa: The Providers list contains the customer's ASID (33554432)."

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
