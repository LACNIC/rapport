#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspa_output "16777472:[123,70000,4294967295]"

check_report fort1 -F "The OID of the SignedObject's content type attribute is not 'aspa'."

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
