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
# Stage 2: A valid delta is generated, then its internal serial is rewritten
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"

DELTA="sandbox/apache2/content/$TEST/delta-step2.rd.xml"
NOTIFICATION="sandbox/apache2/content/$TEST/notification.xml"

# 1. Rewrite the delta file's own root-element serial (2 -> 99).
sed -i 's/serial="2">/serial="99">/' "$DELTA"

# 2. Recompute the (now modified) delta file's SHA-256.
NEWHASH=$(sha256sum "$DELTA" | cut -d' ' -f1)

# 3. Re-align ONLY this delta's hash in the notification.
sed -i "s|\(<delta serial=\"2\" uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\" />\)|\1$NEWHASH\2|" "$NOTIFICATION"

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

check_logfile fort2 -F "Delta serial [99] doesn't match Notification serial [2]"
check_logfile fort2 -F "Falling back to snapshot."
check_logfile fort2 -F "Snapshot exploded."
