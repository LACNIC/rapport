#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspa_output \
	"16777216:[1,2,3,4,5]" \
	"33554432:[111,2121,3838,3839,10000]"

check_logfile fort1 -F "good1.asa: Adding ASPA for customer 16777216"
check_logfile fort1 -F "good2.asa: Adding ASPA for customer 33554432"
check_logfile fort1 -F "bad.asa: The Provider ASIDs are not listed in ascending order."

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
