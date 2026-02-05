#!/bin/sh

# This sample test is a somewhat alternate version of 500-multi-step.
# Instead of relying on deltas, we force the RP to re-snapshot,
# to test that particular pipeline.

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal simple startup run

echo "  Step 1"
run_barry "step1.rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"202::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"2.2.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests


# Stage 2: Some ROAs change

echo "  Step 2"
# Force the HTTP IMS to change
sleep 1
# No delta; we change the session instead
run_barry "step2.rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234" \
	"202::aaaa:0/112-112 => AS1234" \
	"2.1.111.0/24-24 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
