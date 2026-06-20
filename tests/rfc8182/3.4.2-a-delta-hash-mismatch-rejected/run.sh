#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"

# ---------------------------------------------------------------------------
# Stage 1: Initial synchronization (session cafe, serial 1)
# ---------------------------------------------------------------------------

run_barry "step1.rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" 

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests


# ---------------------------------------------------------------------------
# Stage 2: A valid delta is generated, then its served copy is corrupted
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"

# Corrupt the served delta file so its content no longer matches the hash
# advertised in the notification. The notification still references the
# original (correct) hash; only the file bytes change.
truncate -s 1m "sandbox/apache2/content/$TEST/delta-step2.rd.xml"

run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"202::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"2.2.0.0/16-16 => AS1234" 

check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step2.rd.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

check_logfile fort2 -E "File '[^']*' does not match its expected hash\."
check_logfile fort2 -F "Falling back to snapshot."
check_logfile fort2 -F "Snapshot exploded."