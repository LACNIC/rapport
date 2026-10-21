#!/bin/sh

test "$RP" = "fort2" || return 0

# Cycle 1: Normal RRDP cycle
# Cycle 2: Remote deletes RI 4
# Cycle 3: Remote deletes RIs 2 and 3
# Cycle 4: Remote deletes RI 1 (only TA's RI remains)

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

# --------------------------- Step 1 ---------------------------

run_barry "rd1"
run_rp

check_fort_cache 0 6
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "1" "ta/a.cer" "ta/b.cer" "ta/c.cer" "ta/d.cer"
check_rrdp_numbered_cage "1" "1" "a"
check_rrdp_numbered_cage "1" "1" "b"
check_rrdp_numbered_cage "1" "1" "c"
check_rrdp_numbered_cage "1" "1" "d"

# --------------------------- Step 2 ---------------------------

new_step
RRDP_SUBDIRS="a b c" create_delta "rd2"
run_rp

check_fort_cache 0 5
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "2" "ta/a.cer" "ta/b.cer" "ta/c.cer"
check_rrdp_numbered_cage "1" "2" "a"
check_rrdp_numbered_cage "1" "2" "b"
check_rrdp_numbered_cage "1" "2" "c"

# --------------------------- Step 3 ---------------------------

new_step
RRDP_SUBDIRS="a" create_delta "rd3"
run_rp

check_fort_cache 0 3
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "3" "ta/a.cer"
check_rrdp_numbered_cage "1" "3" "a"

# --------------------------- Step 4 ---------------------------

new_step
create_delta "rd4"
run_rp

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_rrdp_root_cage "1" "4"
