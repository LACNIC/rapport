#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1" --rrdp-uri=""
run_rp
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"
check_http_requests
check_rsync_requests "rpki/consecutive-rsync/ta.cer" "rpki/"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"rmt/$TEST/ta/1.roa" \
	"rmt/$TEST/ta/ta.crl" "rmt/$TEST/ta/ta.mft"
check_fort_cache_rsync_cage_end


# Step 2

new_step
create_delta_rsync "rd2" --rrdp-uri=""
run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234"
check_http_requests
check_rsync_requests "rpki/consecutive-rsync/ta.cer" "rpki/"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"rmt/$TEST/ta/1.roa" "rmt/$TEST/ta/2.roa" \
	"rmt/$TEST/ta/ta.crl" "rmt/$TEST/ta/ta.mft"
check_fort_cache_rsync_cage_end

# Step 3

new_step
create_delta_rsync "rd3" --rrdp-uri=""
run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" "300::/8-8 => AS1234"
check_http_requests
check_rsync_requests "rpki/consecutive-rsync/ta.cer" "rpki/"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"rmt/$TEST/ta/1.roa" "rmt/$TEST/ta/2.roa" \
	"rmt/$TEST/ta/3.roa" \
	"rmt/$TEST/ta/ta.crl" "rmt/$TEST/ta/ta.mft"
check_fort_cache_rsync_cage_end

# Step 4

new_step
create_delta_rsync "rd4" --rrdp-uri=""
run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" "300::/8-8 => AS1234" \
	"4.0.0.0/8-8 => AS1234" "400::/8-8 => AS1234"
check_http_requests
check_rsync_requests "rpki/consecutive-rsync/ta.cer" "rpki/"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"rmt/$TEST/ta/1.roa" "rmt/$TEST/ta/2.roa" \
	"rmt/$TEST/ta/3.roa" "rmt/$TEST/ta/4.roa" \
	"rmt/$TEST/ta/ta.crl" "rmt/$TEST/ta/ta.mft"
check_fort_cache_rsync_cage_end
