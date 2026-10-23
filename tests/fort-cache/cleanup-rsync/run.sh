#!/bin/sh

test "$RP" = "fort2" || return 0

# Step 1: Do a normal rsync cycle
# Step 2: Do an offline rsync cycle, check nothing changed

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

BASEURL="rsync://localhost:8873/rpki/$TEST"
NEWPATH="rsync/1/new/$TEST"
RMTPATH="rsync/1/rmt/$TEST"

# --------------------------- Step 1 ---------------------------

run_barry "rd1"
run_rp --http.enabled="false"

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234" \
	"301::/16-16 => AS1234" "3.1.0.0/16-16 => AS1234" \
	"401::/16-16 => AS1234" "4.1.0.0/16-16 => AS1234"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"rmt/$TEST/ta/changes.cer" \
	"rmt/$TEST/ta/drops.cer" \
	"rmt/$TEST/ta/invalidates.cer" \
	"rmt/$TEST/ta/stays.cer" \
	"rmt/$TEST/ta/ta.crl" \
	"rmt/$TEST/ta/ta.mft"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/stays/stays.mft" \
	"rmt/$TEST/stays/stays.crl" \
	"rmt/$TEST/stays/stays.mft" \
	"rmt/$TEST/stays/stays.roa"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/changes/changes.mft" \
	"rmt/$TEST/changes/changes1.roa" \
	"rmt/$TEST/changes/changes.crl" \
	"rmt/$TEST/changes/changes.mft"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/invalidates/invalidates.mft" \
	"rmt/$TEST/invalidates/invalidates.crl" \
	"rmt/$TEST/invalidates/invalidates.mft" \
	"rmt/$TEST/invalidates/invalidates.roa"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/drops/drops.mft" \
	"rmt/$TEST/drops/drops.crl" \
	"rmt/$TEST/drops/drops.mft" \
	"rmt/$TEST/drops/drops.roa"
check_fort_cache_rsync_cage_end

# Not much cleanup happens in this cycle, as everything is fresh.

# Not used in this cage; preserved in a different one.
check_logfile fort2 -F "TRC: rm $RMTPATH/ta.cer"

# --------------------------- Step 2 ---------------------------

new_step
create_delta "rd2"
run_rp --http.enabled="false"

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"202::/16-16 => AS1234" "2.2.0.0/16-16 => AS1234"

check_fort_cache 2 0
check_fort_cache_file "rsync://localhost:8873/rpki/$TEST/ta.cer"
check_fort_cache_rsync_cage_begin "rsync://localhost:8873/rpki"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"rmt/$TEST/ta/changes.cer" \
	"rmt/$TEST/ta/invalidates.cer" \
	"rmt/$TEST/ta/stays.cer" \
	"rmt/$TEST/ta/ta.crl" \
	"rmt/$TEST/ta/ta.mft"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/stays/stays.mft" \
	"rmt/$TEST/stays/stays.crl" \
	"rmt/$TEST/stays/stays.mft" \
	"rmt/$TEST/stays/stays.roa"
check_fort_cache_rsync_fallback \
	"rsync://localhost:8873/rpki/$TEST/changes/changes.mft" \
	"rmt/$TEST/changes/changes2.roa" \
	"rmt/$TEST/changes/changes.crl" \
	"rmt/$TEST/changes/changes.mft"
check_fort_cache_rsync_cage_end

# Old versions of fallbacks are "dropped" (nodes freed and files refput'd)
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/ta/ta.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/changes/changes.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/drops/drops.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/stays/stays.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/invalidates/invalidates.mft (mftnum 01)"

# Valid new files committed
check_logfile fort2 -F "TRC: mv $NEWPATH/changes/changes2.roa $RMTPATH/changes/changes2.roa"
check_logfile fort2 -F "TRC: mv $NEWPATH/changes/changes.mft $RMTPATH/changes/changes.mft"
check_logfile fort2 -F "TRC: mv $NEWPATH/changes/changes.crl $RMTPATH/changes/changes.crl"
check_logfile fort2 -F "TRC: mv $NEWPATH/ta/ta.mft $RMTPATH/ta/ta.mft"
check_logfile fort2 -F "TRC: mv $NEWPATH/ta/ta.crl $RMTPATH/ta/ta.crl"
check_logfile fort2 -F "TRC: mv $NEWPATH/ta/invalidates.cer $RMTPATH/ta/invalidates.cer" # TODO Questionable

# Unfallbacked files rm'd
check_logfile fort2 -F "TRC: rm $RMTPATH/ta.cer"
check_logfile fort2 -F "TRC: rm $RMTPATH/changes/changes1.roa"
check_logfile fort2 -F "TRC: rm $RMTPATH/drops/drops.roa"
check_logfile fort2 -F "TRC: rm $RMTPATH/drops/drops.mft"
check_logfile fort2 -F "TRC: rm $RMTPATH/drops/drops.crl"
check_logfile fort2 -F "TRC: rmdir $RMTPATH/drops"
check_logfile fort2 -F "TRC: rm $RMTPATH/invalidates/invalidates.roa"
check_logfile fort2 -F "TRC: rm $RMTPATH/invalidates/invalidates.mft"
check_logfile fort2 -F "TRC: rm $RMTPATH/invalidates/invalidates.crl"
check_logfile fort2 -F "TRC: rmdir $RMTPATH/invalidates"
check_logfile fort2 -F "TRC: rm $RMTPATH/ta/drops.cer"
