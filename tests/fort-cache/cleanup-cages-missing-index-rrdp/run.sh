#!/bin/sh

test "$RP" = "fort2" || return 0

# Step 1: Do a normal RRDP cycle
# Step 2: Create an HTTP cage missing an index,
#         do a normal RRDP cycle,
#         check the stray cage was simply deleted.

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

# --------------------------- Step 1 ---------------------------

run_barry "rd"
run_rp

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234"

check_fort_cache 0 4
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "1" "ta/a.cer" "ta/b.cer"
check_rrdp_numbered_cage "1" "1" "a"
check_rrdp_numbered_cage "1" "1" "b"

# --------------------------- Step 2 ---------------------------

mkdir "$SANDBOX/workdir/https/4"
touch "$SANDBOX/workdir/https/4/0"
touch "$SANDBOX/workdir/https/4/1"

run_rp

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234"

check_fort_cache 0 4
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "1" "ta/a.cer" "ta/b.cer"
check_rrdp_numbered_cage "1" "1" "a"
check_rrdp_numbered_cage "1" "1" "b"

check_logfile fort2 -F "Cage 4: lacks index, has content, lacks node"
check_logfile fort2 -F "4 is orphaned; Deleting."
