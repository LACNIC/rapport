#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/fort-cache/checks.sh"
. "rp/$RP.sh"

# ---------------------------------------------------------------------------
# Serial 1 -- baseline (served through the fatal run)
# ---------------------------------------------------------------------------

run_barry rd1
run_rp "--rsync.enabled=false"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

check_vrps \
	"1.1.0.0/16-16 => AS64501"
	
# ---------------------------------------------------------------------------
# Serials 2, 3, 4 -- all RPP-fatal; FORT keeps serving serial 1
# ---------------------------------------------------------------------------

new_step
create_delta rd2
run_rp "--rsync.enabled=false"

check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd2.xml 200"
check_rsync_requests

check_vrps \
	"1.1.0.0/16-16 => AS64501"

new_step
create_delta rd3
run_rp "--rsync.enabled=false"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd3.xml 200"
check_rsync_requests

check_vrps \
	"1.1.0.0/16-16 => AS64501"

new_step
create_delta rd4
run_rp "--rsync.enabled=false"

check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd4.xml 200"
check_rsync_requests

check_vrps \
	"1.1.0.0/16-16 => AS64501"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"

# Refresh step: FORT caches the full serial 4 (incl. A4.roa).
check_fort_cache_rrdp_step "1" "4" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

# Fallback for CA A: serial 2's set (A1+A2), manifest 02.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end

# ---------------------------------------------------------------------------
# Serial 5 -- valid recovery; jump from serial 1 to serial 5 via delta
# ---------------------------------------------------------------------------

new_step
create_delta rd5
run_rp "--rsync.enabled=false"

# Recovery via delta.
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd5.xml 200"
check_rsync_requests

# Served set jumps to serial 5's full VRPs: A1..A5 all validate now.
check_vrps \
	"1.1.0.0/16-16 => AS64501" \
	"1.2.0.0/16-16 => AS64502" \
	"1.3.0.0/16-16 => AS64503" \
	"1.4.0.0/16-16 => AS64504" \
	"1.5.0.0/16-16 => AS64505"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"

# Serial 5 is now the newest step, full valid set.
check_fort_cache_rrdp_step "1" "5" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A5.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

# Fallback for CA A: serial 5 becomes the new fallback, manifest 05, replacing serial 1.
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A3.roa" "A/A4.roa" "A/A5.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_cage_end
