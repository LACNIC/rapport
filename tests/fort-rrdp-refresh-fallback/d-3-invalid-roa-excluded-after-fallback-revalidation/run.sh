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
# Serial 3 -- valid update (expected served serial & fallback)
# ---------------------------------------------------------------------------

new_step
create_delta rd3
run_rp "--rsync.enabled=false"

check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502" \
	"1.3.0.0/16-16 => AS64503"

# ---------------------------------------------------------------------------
# Serial 4 -- RPP-no-fatal (invalid A4.roa); FORT must serve serial 4
# ---------------------------------------------------------------------------

new_step
create_delta rd4
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

# Fallback: EXPECTED serial-4 state (include A4.roa), because an invalid ROA signature 
# does not trigger an RRDP fallback; only the resources from A4.roa are discarded.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end

# ---------------------------------------------------------------------------
# Serial 5 -- Serial 5 is RPP-fatal. FORT walks back to serial 4 and
# re-validates it. A4 must remain excluded.
# ---------------------------------------------------------------------------

new_step
create_delta rd5

run_rp "--rsync.enabled=false"

# THE ASSERTION: A4's resource is STILL absent -- produced by a
# re-validation of serial 4's fallback RPP.
check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502" \
	"1.3.0.0/16-16 => AS64503"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"

# Serial 5 is the newest refresh step (the fatal one): same file names as
# serial 4, but A.mft is now the corrupt (manifest 05) version.
check_fort_cache_rrdp_step "1" "5" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A5.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

# Fallback stays serial 4's VALID RPP (manifest 04), INCLUDING A4.roa. FORT
# re-validated it and again excluded A4: A4.roa is cached in the fallback but
# never served.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end
