#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry "$TEST.rd"
run_rp

check_vrp_count 0

check_report fort2       -F "ROA's version (2) is nonzero."
check_report rpki-client -F "unexpected version (expected 0, got 2)"
# TODO prover & routinator

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
