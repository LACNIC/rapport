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
# Stage 2: The notification advertises the delta at a foreign origin
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"

# Rewrite the <delta> uri so its origin (scheme://host:port) differs from the
# notification's own origin.
sed -i \
	's|<delta serial="2" uri="https://localhost:8443/|<delta serial="2" uri="https://attacker.example:8443/|' \
	"sandbox/apache2/content/$TEST/notification.xml"

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
	"/$TEST/notification.xml 200"
check_rsync_requests \
	"rpki/"

check_logfile fort2 -F "TRE: (Line 6) Notification 'https://localhost:8443/$TEST/notification.xml' does not have the same origin as its Delta: https://attacker.example:8443/$TEST/delta-step2.rd.xml"
check_logfile fort2 -F "TRE: Error requesting URL: Failure writing output to destination. (HTTP code: 200)"
