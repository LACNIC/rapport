#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/fort-cache/checks.sh"
. "rp/$RP.sh"

# ---------------------------------------------------------------------------
# Serial 1 -- baseline fallback state
# ---------------------------------------------------------------------------

run_barry rd1
run_rp "--rsync.enabled=false"

check_vrps \
	"1.1.0.0/16-16 => AS64501"
	
# ---------------------------------------------------------------------------
# Serial 2 -- valid update
# ---------------------------------------------------------------------------

new_step
create_delta rd2
run_rp "--rsync.enabled=false"

check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502"

# ---------------------------------------------------------------------------
# Serial 3 -- RPP-fatal (invalid A.mft); FORT stays on serial 2
# ---------------------------------------------------------------------------

new_step
create_delta rd3
run_rp "--rsync.enabled=false"

check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502"

# ---------------------------------------------------------------------------
# Serial 4 -- RPP-fatal (invalid A.mft); FORT must serve serial 2
# ---------------------------------------------------------------------------

new_step
create_delta rd4
run_rp "--rsync.enabled=false"

check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"

# Refresh step: FORT caches the full serial 4 (incl. A4.roa).
check_fort_cache_rrdp_step "1" "4" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

# Fallback for CA A: serial 2's set (A1+A2), manifest 02. ---
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end
