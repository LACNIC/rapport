#!/bin/sh

# This sample test involves incremental validation cycles.
# The RP will have to deal with caching and RRDP deltas.

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal simple startup run

echo "  Step 1"
run_barry "step1.rd"
run_rp

check_vrps \
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
# create_delta() is the incremental counterpart of the snapshot-y run_barry().
# It computes the delta between the existing RRDP stage and the given new RD,
# and places it in the apache server.
# The rsync box is updated too.
create_delta "step2.rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"
# This time we expect the RP to not query the snapshot;
# we want it to apply the smaller delta instead.
# Notice that the TA is queried but not re-downloaded.
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step2.rd.xml 200"
check_rsync_requests


# Stage 3: Both RRDP and rsync die, RP needs to fallback

echo "  Step 3"
# Instead of running Barry, get rid of both server contents.
# As they will be absent, the RP will be unable to download them.
mv "sandbox/apache2/content/$TEST" "$SANDBOX/tmp-apache2"
mv "sandbox/rsyncd/content/$TEST" "$SANDBOX/tmp-rsync"
run_rp

# The RP attempts to download relevant files, but all attempts fail.
check_http_requests \
	"/$TEST/ta.cer 404" \
	"/$TEST/notification.xml 404"
# The rsync log doesn't seem to tell us whether the download failed,
# at least with the current configuration, so this will have to do for now.
check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"

# In spite of the hiccup, the RP continues serving the same VRPs as in the
# previous cycle, because it falls back to its cache.
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"2.22.0.0/16-16 => AS1234" "222::/16-16 => AS1234" \
	"301::/16-16 => AS1234" "302::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" "3.2.0.0/16-16 => AS1234" \
	"601::/16-16 => AS1234" "6.1.0.0/16-16 => AS1234"


# Stage 4: RRDP and rsync come back online, RP recovers via delta

echo "  Step 4"
mv "$SANDBOX/tmp-apache2" "sandbox/apache2/content/$TEST"
mv "$SANDBOX/tmp-rsync" "sandbox/rsyncd/content/$TEST"
create_delta "step4.rd"
run_rp

check_vrps "101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step4.rd.xml 200"
check_rsync_requests
