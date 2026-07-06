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
# Stage 2: A legitimate delta is generated, then an unknown-object withdraw is
#          injected into it
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"

DELTA="sandbox/apache2/content/$TEST/delta-step2.rd.xml"
NOTIFICATION="sandbox/apache2/content/$TEST/notification.xml"

# 1. Inject a <withdraw> for a URI this notification never published.
UNKNOWN_HASH=$(printf '0%.0s' $(seq 1 64))
sed -i "s#</delta>#  <withdraw uri=\"rsync://localhost/other/UNKNOWN.roa\" hash=\"$UNKNOWN_HASH\" />\n</delta>#" "$DELTA"

# 2. Recompute the (now modified) delta file's SHA-256.
NEWHASH=$(sha256sum "$DELTA" | cut -d' ' -f1)

# 3. Re-align ONLY this delta's hash in the notification so validate_hash passes.
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

check_logfile fort2 -F "Broken RRDP: <withdraw> is attempting to delete unknown file 'rsync://localhost/other/UNKNOWN.roa'."
check_logfile fort2 -F "Falling back to snapshot."
check_logfile fort2 -F "Snapshot exploded."
