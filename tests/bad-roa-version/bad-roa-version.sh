#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry "$TEST.rd"
run_rp

check_vrp_count 0
check_output "report.txt" -F "ROA's version (2) is nonzero."
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
