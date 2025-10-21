#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal, simple run

run_barry "step1.rd"
run_rp

check_vrp_output \
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

create_delta "step2.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234" \
	"202::aaaa:0/112-112 => AS1234" \
	"2.1.111.0/24-24 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step2.rd.xml 200"
check_rsync_requests


# Stage 3: Both RRDP and rsync die, RP needs to fallback

rm -r "sandbox/apache2/content/$TEST"
rm -r "sandbox/rsyncd/content/$TEST"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234" \
	"202::aaaa:0/112-112 => AS1234" \
	"2.1.111.0/24-24 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 404" \
	"/$TEST/notification.xml 404"
check_rsync_requests \
	"rpki/multi-step/ta.cer" \
	"rpki/"
