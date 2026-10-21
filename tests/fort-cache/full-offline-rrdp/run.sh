#!/bin/sh

test "$RP" = "fort2" || return 0

# Step 1: Do a normal RRDP cycle
# Step 2: Do an offline RRDP cycle, check nothing changed

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

run_rp --http.enabled="false" --rsync.enabled="false"
check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234"

check_fort_cache 0 4
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "1" "ta/a.cer" "ta/b.cer"
check_rrdp_numbered_cage "1" "1" "a"
check_rrdp_numbered_cage "1" "1" "b"
