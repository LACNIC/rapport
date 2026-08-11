#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/fort-cache/checks.sh"
. "rp/$RP.sh"

# ---------------------------------------------------------------------------
# Single snapshot at serial 1 (no delta chain).
# ---------------------------------------------------------------------------

run_barry rd1
run_rp "--rsync.enabled=false"

check_vrps

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"


check_fort_cache_rrdp_step "1" "1" \
	"A/A1.roa" "A/A.crl" "A/A.mft" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"

check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/A"

check_fort_cache_cage_end
