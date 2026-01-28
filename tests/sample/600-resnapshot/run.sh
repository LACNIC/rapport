#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal, simple run

echo "  Step 1"
run_barry "step1.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"202::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"2.2.0.0/16-16 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "cafe-1" "1" \
	"A/A1.roa" "A/A2.roa" "A/A.crl" "A/A.mft" \
	"B/B1.roa" "B/B2.roa" "B/B.crl" "B/B.mft" \
	"ta/A.cer" "ta/B.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "cafe-1" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/B.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "cafe-1" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "cafe-1" "rsync://localhost:8873/rpki/$TEST/B" \
	"B/B1.roa" "B/B2.roa" "B/B.crl" "B/B.mft"
check_fort_cache_cage_end

# TODO cleanup properly
rm "$SANDBOX/rrdp/"*

# Stage 2: Some ROAs change

echo "  Step 2"
sleep 1
run_barry "step2.rd"
run_rp

check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234" \
	"202::aaaa:0/112-112 => AS1234" \
	"2.1.111.0/24-24 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "cafe-2" "1" \
	"A/A1.roa" "A/A2.roa" "A/A.crl" "A/A.mft" \
	"C/C1.roa" "C/C2.roa" "C/C.crl" "C/C.mft" \
	"ta/A.cer" "ta/C.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "cafe-2" "rsync://localhost:8873/rpki/$TEST/ta" \
	"ta/A.cer" "ta/C.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "cafe-2" "rsync://localhost:8873/rpki/$TEST/A" \
	"A/A1.roa" "A/A2.roa" "A/A.crl" "A/A.mft"
check_fort_cache_rrdp_fallback "cafe-2" "rsync://localhost:8873/rpki/$TEST/C" \
	"C/C1.roa" "C/C2.roa" "C/C.crl" "C/C.mft"
check_fort_cache_cage_end
