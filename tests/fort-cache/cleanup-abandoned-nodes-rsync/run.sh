#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

# --------------------------- Step 1 ---------------------------

run_barry "rd1" --rrdp-uri=""
move_rsync_cages_to_repos "1" "2" "3" "4"
run_rp --http.enabled="false"

check_fort_cache 6 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage \
	"rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer" \
	"rmt/$TEST/ta/3.cer" "rmt/$TEST/ta/4.cer"
check_numbered_cage "1"
check_numbered_cage "2"
check_numbered_cage "3"
check_numbered_cage "4"

# --------------------------- Step 2 ---------------------------

restore_rsync_cages_to_barry_workspace "1" "2" "3" "4"
new_step
run_barry "rd2" --rrdp-uri=""
move_rsync_cages_to_repos "1" "2" "3"
run_rp --http.enabled="false"

check_fort_cache 5 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage \
	"rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer" "rmt/$TEST/ta/3.cer"
check_numbered_cage "1"
check_numbered_cage "2"
check_numbered_cage "3"

# --------------------------- Step 3 ---------------------------

restore_rsync_cages_to_barry_workspace "1" "2" "3"
new_step
run_barry "rd3" --rrdp-uri=""
move_rsync_cages_to_repos "1"
run_rp --http.enabled="false"

check_fort_cache 3 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage "rmt/$TEST/ta/1.cer"
check_numbered_cage "1"

# --------------------------- Step 4 ---------------------------

new_step
run_barry "rd4" --rrdp-uri=""
run_rp --http.enabled="false"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage
