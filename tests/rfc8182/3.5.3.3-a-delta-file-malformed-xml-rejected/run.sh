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
# Stage 2: malformed XML - delta root element closed with a wrong tag
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"

DELTA="sandbox/apache2/content/$TEST/delta-step2.rd.xml"
NOTIFICATION="sandbox/apache2/content/$TEST/notification.xml"

sed -i 's#</delta>#</deltaX>#' "$DELTA"

NEWHASH=$(sha256sum "$DELTA" | cut -d' ' -f1)
sed -i "s|\(<delta serial=\"2\" uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\" />\)|\1$NEWHASH\2|" "$NOTIFICATION"

run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"202::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"2.2.0.0/16-16 => AS1234"

check_logfile fort2 -F "Falling back to snapshot."
check_logfile fort2 -F "Snapshot exploded."