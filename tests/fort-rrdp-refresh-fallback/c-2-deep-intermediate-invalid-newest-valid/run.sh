#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/fort-cache/checks.sh"
. "rp/$RP.sh"

# ---------------------------------------------------------------------------
# Build the full delta chain 1->4 WITHOUT validating in between, so the
# notification advertises serial 4 and all deltas are present when FORT
# first runs.
# ---------------------------------------------------------------------------

run_barry rd1

new_step
create_delta rd2

new_step
create_delta rd3

new_step
create_delta rd4

# ---------------------------------------------------------------------------
# Single validation pass over the whole chain (serial 4 advertised).
# ---------------------------------------------------------------------------

run_rp "--rsync.enabled=false"

# Served set: EXPECTED serial 4's VRPs (A1..A4), FORT having walked over
# the fatal serial 3. If FORT falls back to serial 2 instead, this warns.
check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502" \
	"1.3.0.0/16-16 => AS64503" \
	"1.4.0.0/16-16 => AS64504"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"

# Newest step: EXPECTED serial 4 with its full valid set. ---
check_fort_cache_rrdp_step "1" "4" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

# Fallback for CA A: EXPECTED serial 4's set (newest valid), manifest 04.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end
