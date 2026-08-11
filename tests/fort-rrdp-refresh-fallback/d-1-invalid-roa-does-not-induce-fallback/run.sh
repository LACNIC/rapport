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

check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502" \
	"1.3.0.0/16-16 => AS64503"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"

# Refresh step: FORT caches the full serial 4 (incl. A4.roa).
check_fort_cache_rrdp_step "1" "4" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

# Fallback for CA A: serial 4's RPP, manifest 04, INCLUDING A4.roa. This
# is the crux vs a-1: the fallback does NOT retreat to serial 3; the
# invalid ROA stays in the RPP-level fallback set.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end
