#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Stage 1: Normal, simple run

echo "$TEST: Step 1"
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

check_fort_cache 0 1 1 4
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa" \
	"B/B.crl" "B/B.mft" "B/B1.roa" "B/B2.roa" \
	"ta/A.cer" "ta/B.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
check_fort_cache_cage fallback "ta/A.cer" "ta/B.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa"
check_fort_cache_cage fallback "B/B.crl" "B/B.mft" "B/B1.roa" "B/B2.roa"

# Stage 2: Some ROAs change

echo "$TEST: Step 2"
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

check_fort_cache 0 1 1 5
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa" \
	"C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa" \
	"ta/A.cer" "ta/C.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback 
check_fort_cache_cage fallback \
	"ta/A.cer" "ta/B.cer" "ta/C.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa"
check_fort_cache_cage fallback "B/B.crl" "B/B.mft" "B/B1.roa" "B/B2.roa"
check_fort_cache_cage fallback "C/C.crl" "C/C.mft" "C/C1.roa" "C/C2.roa"
