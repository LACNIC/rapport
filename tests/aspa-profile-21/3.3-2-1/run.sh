#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrp_count 0
check_aspa_output "16777216:[100,200,300]"

check_logfile fort1 -F "Adding ASPA for customer 16777216"
check_logfile fort1 -F "not-as.asa: Provider out of range. (0-4294967295)"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
