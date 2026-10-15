#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

# --------------------------- Step 1 ---------------------------

run_barry "rd1"
run_rp

check_fort_cache 0 6
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"

check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
FILES="ta/a.cer ta/b.cer ta/c.cer ta/d.cer ta/ta.crl ta/ta.mft"
check_fort_cache_rrdp_step "1" "1" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/a/notification.xml"
FILES="a/a.crl a/a.mft a/a.roa"
check_fort_cache_rrdp_step "1" "1" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/a/a.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/b/notification.xml"
FILES="b/b.crl b/b.mft b/b.roa"
check_fort_cache_rrdp_step "1" "1" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/b/b.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/c/notification.xml"
FILES="c/c.crl c/c.mft c/c.roa"
check_fort_cache_rrdp_step "1" "1" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/c/c.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/d/notification.xml"
FILES="d/d.crl d/d.mft d/d.roa"
check_fort_cache_rrdp_step "1" "1" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/d/d.mft" $FILES
check_fort_cache_cage_end

# --------------------------- Step 2 ---------------------------

new_step
RRDP_SUBDIRS="a b c" create_delta "rd2"
run_rp

check_fort_cache 0 5
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"

check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
FILES="ta/a.cer ta/b.cer ta/c.cer ta/ta.crl ta/ta.mft"
check_fort_cache_rrdp_step "1" "2" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/a/notification.xml"
FILES="a/a.crl a/a.mft a/a.roa"
check_fort_cache_rrdp_step "1" "2" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/a/a.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/b/notification.xml"
FILES="b/b.crl b/b.mft b/b.roa"
check_fort_cache_rrdp_step "1" "2" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/b/b.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/c/notification.xml"
FILES="c/c.crl c/c.mft c/c.roa"
check_fort_cache_rrdp_step "1" "2" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/c/c.mft" $FILES
check_fort_cache_cage_end

# --------------------------- Step 3 ---------------------------

new_step
RRDP_SUBDIRS="a" create_delta "rd3"
run_rp

check_fort_cache 0 3
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"

check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
FILES="ta/a.cer ta/ta.crl ta/ta.mft"
check_fort_cache_rrdp_step "1" "3" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" $FILES
check_fort_cache_cage_end

check_fort_cache_cage_begin "https://localhost:8443/$TEST/a/notification.xml"
FILES="a/a.crl a/a.mft a/a.roa"
check_fort_cache_rrdp_step "1" "3" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/a/a.mft" $FILES
check_fort_cache_cage_end

# --------------------------- Step 4 ---------------------------

new_step
create_delta "rd4"
run_rp

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"

check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
FILES="ta/ta.crl ta/ta.mft"
check_fort_cache_rrdp_step "1" "4" $FILES
check_fort_cache_rrdp_fallback "1" "rsync://localhost:8873/rpki/$TEST/ta/ta.mft" $FILES
check_fort_cache_cage_end
