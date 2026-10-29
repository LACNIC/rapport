#!/bin/sh

test "$RP" = "fort2" || return 0

# Step 1: Do a normal rsync cycle
# Step 2: Create an rysnc cage missing an index,
#         do a normal rsync cycle,
#         check the stray cage was simply deleted.

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
check_rsync_root_cage "rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer"
check_rsync_numbered_cage "1"
check_rsync_numbered_cage "2"

# --------------------------- Step 2 ---------------------------

mkdir -p "$SANDBOX/workdir/rsync/4/rmt"
touch "$SANDBOX/workdir/rsync/4/rmt/0"
touch "$SANDBOX/workdir/rsync/4/rmt/1"

run_rp --http.enabled="false"

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234"

check_fort_cache 4 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_rsync_root_cage "rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer"
check_rsync_numbered_cage "1"
check_rsync_numbered_cage "2"

check_logfile fort2 -F "WRN: rsync/4.json: File does not exist."
check_logfile fort2 -F "TRC:   Cage 4: lacks index, has content, lacks node"
check_logfile fort2 -F "TRC:   4 is orphaned; Deleting."
