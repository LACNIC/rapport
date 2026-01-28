#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


run_barry "rd" --rrdp-uri "" --rrdp-path ""
run_rp


check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234"

check_http_requests
check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"
