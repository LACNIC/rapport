#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal, simple run

echo "  Step 1"
run_barry "step1.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234" \
	"301::/16-16 => AS1234" "3.1.0.0/16-16 => AS1234" \
	"401::/16-16 => AS1234" "4.1.0.0/16-16 => AS1234" \
	"501::/16-16 => AS1234" "5.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests


# Stage 2: Some ROAs change

echo "  Step 2"
create_delta "step2.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step2.rd.xml 200"
check_rsync_requests


# Stage 3: Both RRDP and rsync die, RP needs to fallback

echo "  Step 3"
mv "sandbox/apache2/content/$TEST" "$SANDBOX/tmp-apache2"
mv "sandbox/rsyncd/content/$TEST" "$SANDBOX/tmp-rsync"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 404" \
	"/$TEST/notification.xml 404"
#check_rsync_requests \
#	"rpki/$TEST/ta.cer" \
#	"rpki/"


# Stage 4: RRDP and rsync come back, RP recovers via delta

echo "  Step 4"
mv "$SANDBOX/tmp-apache2" "sandbox/apache2/content/$TEST"
mv "$SANDBOX/tmp-rsync" "sandbox/rsyncd/content/$TEST"
create_delta "step4.rd"
run_rp

check_vrp_output "101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step4.rd.xml 200"
check_rsync_requests
