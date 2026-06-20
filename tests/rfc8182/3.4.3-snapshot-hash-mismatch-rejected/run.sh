#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"

# ---------------------------------------------------------------------------
# Single synchronization: the snapshot is corrupted before the RP fetches it
# ---------------------------------------------------------------------------

run_barry rd

# Corrupt the served snapshot so its content no longer matches the hash
# advertised in the notification.
truncate -s 1m "sandbox/apache2/content/$TEST/snapshot.xml"

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
check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"

check_logfile fort2 -E "File '[^']*' does not match its expected hash\."