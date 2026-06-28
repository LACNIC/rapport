#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"

# ---------------------------------------------------------------------------
# Stage 1: cold-cache synchronization (session cafe, serial 1)
# ---------------------------------------------------------------------------

run_barry "step1.rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests


# ---------------------------------------------------------------------------
# Stage 2: a real, valid delta is applied (serial 1 -> 2, adds B.roa).
# This is the round whose hash the RP is expected to record.
# ---------------------------------------------------------------------------

new_step
create_delta "step2.rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" 

check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-step2.rd.xml 200"
check_rsync_requests

check_logfile fort2 -F "Delta exploded."


# ---------------------------------------------------------------------------
# Stage 3: a new, valid delta is published (serial 2 -> 3, adds C.roa), and
# the carried-forward serial=2 notification entry is tampered with a
# different hash, simulating the server having mutated that Delta File at
# some point after it was originally fetched and applied in stage 2.
# ---------------------------------------------------------------------------

new_step
create_delta "step3.rd"

NOTIFICATION="sandbox/apache2/content/$TEST/notification.xml"

# A random, obviously-different 64-hex-char value. No real hash computation is
# needed: this check never re-fetches delta-step2.rd.xml, it only compares the
# notification's advertised hash against what the RP recorded in stage 2.
MUTATED_HASH=$(openssl rand -hex 32)
sed -i "s|\(<delta serial=\"2\" uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\" />\)|\1$MUTATED_HASH\2|" "$NOTIFICATION"

run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"301::/16-16 => AS1234" \
	"3.1.0.0/16-16 => AS1234" 

check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

check_logfile fort2 -F "RRDP session desynchronization detected."
check_logfile fort2 -F "Falling back to snapshot."
check_logfile fort2 -F "Snapshot exploded."
