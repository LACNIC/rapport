#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry_default "$TEST.rd"
run_rp_default

check_vrp_count 0
check_output "report.txt" -F "ROA's version (2) is nonzero."
check_http_requests \
	"/rrdp/ta.cer 200" \
	"/rrdp/notification.xml 200" \
	"/rrdp/notification.xml.snapshot 200"
check_rsync_requests
