#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

# --------------------------- Step 1 ---------------------------

run_barry "rd" --rrdp-uri=""
move_rsync_cages_to_repos "1" "2"

run_rp --http.enabled="false"
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234"

check_fort_cache 4 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage "rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer"
check_numbered_cage "1"
check_numbered_cage "2"

# --------------------------- Step 2 ---------------------------

clear_rsync_modules
run_rp --http.enabled="false" --rsync.enabled="false"
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234"

check_fort_cache 4 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage "rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer"
check_numbered_cage "1"
check_numbered_cage "2"
