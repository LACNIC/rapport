#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspa_output "16777489:[4369]"

check_logfile fort1 -F "correct.asa: Adding ASPA for customer 16777489"
check_logfile fort1 -F "not-1.asa: Version number is not 1: 2"
check_logfile fort1 -F "implicit.asa: Version number is NULL."

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
