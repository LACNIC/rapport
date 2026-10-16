#!/bin/sh

test "$RP" = "fort2" || return 0

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

check_root_cage() {
	check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
	check_fort_cache_rsync_fallback \
		"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
		"$@" "rmt/$TEST/ta/ta.crl" "rmt/$TEST/ta/ta.mft"
	check_fort_cache_rsync_cage_end
}

check_numbered_cage() {
	check_fort_cache_rsync_cage_begin "rsync://localhost:8873/repo$1"
	check_fort_cache_rsync_fallback \
		"rsync://localhost:8873/repo$1/$TEST/$1/$1.mft" \
		"rmt/$TEST/$1/$1.crl" "rmt/$TEST/$1/$1.mft" \
		"rmt/$TEST/$1/$1.roa"
	check_fort_cache_rsync_cage_end
}

# --------------------------- Step 1 ---------------------------

run_barry "rd1" --rrdp-uri=""
for i in 1 2 3 4; do
	mkdir "sandbox/rsyncd/repo$i/$TEST"
	mv "sandbox/rsyncd/content/$TEST/$i" "sandbox/rsyncd/repo$i/$TEST"
done
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

for i in 1 2 3 4; do
	mv "sandbox/rsyncd/repo$i/$TEST/$i" "sandbox/rsyncd/content/$TEST"
done
new_step
run_barry "rd2" --rrdp-uri=""
for i in 1 2 3; do
	mv "sandbox/rsyncd/content/$TEST/$i" "sandbox/rsyncd/repo$i/$TEST"
done
run_rp --http.enabled="false"

check_fort_cache 5 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_root_cage \
	"rmt/$TEST/ta/1.cer" "rmt/$TEST/ta/2.cer" "rmt/$TEST/ta/3.cer"
check_numbered_cage "1"
check_numbered_cage "2"
check_numbered_cage "3"

# --------------------------- Step 3 ---------------------------

for i in 1 2 3; do
	mv "sandbox/rsyncd/repo$i/$TEST/$i" "sandbox/rsyncd/content/$TEST"
done
new_step
run_barry "rd3" --rrdp-uri=""
mv "sandbox/rsyncd/content/$TEST/1" "sandbox/rsyncd/repo1/$TEST"
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
