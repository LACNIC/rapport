#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"
run_rp
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "1" \
	"ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/1.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end

# Step 2

new_step
create_delta "rd2"
run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd2.xml 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "2" \
	"ta/1.roa" "ta/2.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/1.roa" "ta/2.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end

# Step 3

new_step
create_delta "rd3"
run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" "300::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd3.xml 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "3" \
	"ta/1.roa" "ta/2.roa" "ta/3.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/1.roa" "ta/2.roa" "ta/3.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end

# Step 4

new_step
create_delta "rd4"
run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" "300::/8-8 => AS1234" \
	"4.0.0.0/8-8 => AS1234" "400::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/$TEST/delta-rd4.xml 200"
check_rsync_requests

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "4" \
	"ta/1.roa" "ta/2.roa" "ta/3.roa" "ta/4.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/1.roa" "ta/2.roa" "ta/3.roa"  "ta/4.roa" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage_end
