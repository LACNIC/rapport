#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"

# ---------------------------------------------------------------------------
# Stage 1: Full successful synchronization over RRDP (session cafe, serial 1)
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
# Stage 2: Both transports fail for the publication point; cache must persist
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"

# Remove the RPP content from BOTH transports, but keep ta.cer reachable so the
# RP can still read the SIA and attempt (and fail) each access method.
rm -f "sandbox/apache2/content/$TEST/notification.xml" \
      "sandbox/apache2/content/$TEST/snapshot.xml" \
      "sandbox/apache2/content/$TEST"/delta-*.xml

# rsync side (rsyncd): empty the publication point tree.
rm -rf "sandbox/rsyncd/content/$TEST"
mkdir -p "sandbox/rsyncd/content/$TEST"

run_rp

# The cache from step1 must be preserved.
check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" 

check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 404"
check_rsync_requests \
	"rpki/"