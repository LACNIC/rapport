#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"


run_barry
run_rp


# Same as sample/200-bad-roa-version
check_vrp_count 0
check_report fort2       -F "ROA's version (2) is nonzero."
check_report rpki-client -F "unexpected version (expected 0, got 2)"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests


check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "1" \
	"ta/roa.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/roa.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end
