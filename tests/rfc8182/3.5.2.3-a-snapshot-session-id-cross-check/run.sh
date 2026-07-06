#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"

# ---------------------------------------------------------------------------
# Stage 1: Valid initial synchronization (session cafe, serial 1)
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
# Stage 2: New session forces a snapshot whose internal session_id is tampered
# ---------------------------------------------------------------------------

new_step
run_barry "step2.rd"

SNAPSHOT="sandbox/apache2/content/$TEST/snapshot.xml"
NOTIFICATION="sandbox/apache2/content/$TEST/notification.xml"

# Rewrite the snapshot's own session_id (beef -> cafe) so it no longer matches
# the session_id the notification announces (beef).
sed -i 's/session_id="beef"/session_id="cafe"/' "$SNAPSHOT"

# Recompute the snapshot's SHA-256 and re-align it in the notification so
# hash verification passes and the session_id cross-check is the operative one.
NEWHASH=$(sha256sum "$SNAPSHOT" | cut -d' ' -f1)
sed -i "s|\(<snapshot uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\"/>\)|\1$NEWHASH\2|" "$NOTIFICATION"

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
	"/$TEST/snapshot.xml 200"
check_rsync_requests \
	"rpki/"

check_logfile fort2 -F "Snapshot session id [beef] doesn't match Notification session id [cafe]"
