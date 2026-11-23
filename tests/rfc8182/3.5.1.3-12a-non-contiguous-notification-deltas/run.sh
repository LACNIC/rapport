#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"

run_rp
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

# Step 2

new_step
create_delta "rd2"

# Step 3

new_step
create_delta "rd3"

# Step 4

new_step
create_delta "rd4"
sed -i"" 's#<delta serial="3" .*/>##' "sandbox/apache2/8443/content/$TEST/notification.xml"

run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" "300::/8-8 => AS1234" \
	"4.0.0.0/8-8 => AS1234" "400::/8-8 => AS1234"
check_http_requests "/$TEST/ta.cer 304" "/$TEST/notification.xml 200"
check_rsync_requests "rpki/"
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/notification.xml: The serials listed in the Notification's deltas do not form a contiguous sequence"
