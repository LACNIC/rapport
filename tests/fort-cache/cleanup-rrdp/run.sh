#!/bin/sh

test "$RP" = "fort2" || return 0

# Step 1: Do a normal rsync cycle
# Step 2: Do an offline rsync cycle, check nothing changed

. "tools/checks.sh"
. "tests/$CATEGORY/checks.sh"
. "rp/$RP.sh"

# --------------------------- Step 1 ---------------------------

run_barry "rd1"
run_rp

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" "2.1.0.0/16-16 => AS1234" \
	"301::/16-16 => AS1234" "3.1.0.0/16-16 => AS1234" \
	"401::/16-16 => AS1234" "4.1.0.0/16-16 => AS1234"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "1" \
	"changes/changes1.roa" "changes/changes.crl" "changes/changes.mft" \
	"drops/drops.crl" "drops/drops.mft" "drops/drops.roa" \
	"invalidates/invalidates.crl" "invalidates/invalidates.mft" "invalidates/invalidates.roa" \
	"stays/stays.crl" "stays/stays.mft" "stays/stays.roa" \
	"ta/changes.cer" "ta/drops.cer" "ta/invalidates.cer" "ta/stays.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/changes.cer" \
	"ta/drops.cer" \
	"ta/invalidates.cer" \
	"ta/stays.cer" \
	"ta/ta.crl" \
	"ta/ta.mft"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/stays/stays.mft" \
	"stays/stays.crl" \
	"stays/stays.mft" \
	"stays/stays.roa"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/changes/changes.mft" \
	"changes/changes1.roa" \
	"changes/changes.crl" \
	"changes/changes.mft"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/invalidates/invalidates.mft" \
	"invalidates/invalidates.crl" \
	"invalidates/invalidates.mft" \
	"invalidates/invalidates.roa"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/drops/drops.mft" \
	"drops/drops.crl" \
	"drops/drops.mft" \
	"drops/drops.roa"
check_fort_cache_cage_end

# No cleanup happens in this cycle, as everything is fresh.

# --------------------------- Step 2 ---------------------------

new_step
create_delta "rd2"
run_rp

check_vrps \
	"101::/16-16 => AS1234" "1.1.0.0/16-16 => AS1234" \
	"202::/16-16 => AS1234" "2.2.0.0/16-16 => AS1234"

check_fort_cache 0 2
check_fort_cache_file "https://localhost:8443/$TEST/ta.cer"
check_fort_cache_cage_begin "https://localhost:8443/$TEST/notification.xml"
check_fort_cache_rrdp_step "1" "2" \
	"changes/changes2.roa" "changes/changes.crl" "changes/changes.mft" \
	"invalidates/invalidates.crl" "invalidates/invalidates.mft" "invalidates/invalidates.roa" \
	"stays/stays.crl" "stays/stays.mft" "stays/stays.roa" \
	"ta/changes.cer" "ta/invalidates.cer" "ta/stays.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/ta/ta.mft" \
	"ta/changes.cer" \
	"ta/invalidates.cer" \
	"ta/stays.cer" \
	"ta/ta.crl" \
	"ta/ta.mft"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/stays/stays.mft" \
	"stays/stays.crl" \
	"stays/stays.mft" \
	"stays/stays.roa"
check_fort_cache_rrdp_fallback "1" \
	"rsync://localhost:8873/rpki/$TEST/changes/changes.mft" \
	"changes/changes2.roa" \
	"changes/changes.crl" \
	"changes/changes.mft"
check_fort_cache_cage_end

check_logfile fort2 -F "TRE: Certificate version is not v3."

# Old versions of fallbacks are "dropped" (nodes freed and files refput'd)
BASEURL="rsync://localhost:8873/rpki/$TEST"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/ta/ta.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/changes/changes.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/drops/drops.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/stays/stays.mft (mftnum 01)"
check_logfile fort2 -F "TRC: Dropping fallback: $BASEURL/invalidates/invalidates.mft (mftnum 01)"

# Session cleans
REMOVALS="$BASEURL/ta/drops.cer \
	$BASEURL/ta/invalidates.cer \
	$BASEURL/ta/ta.mft \
	$BASEURL/ta/ta.crl \
	$BASEURL/changes/changes1.roa \
	$BASEURL/changes/changes.mft \
	$BASEURL/changes/changes.crl \
	$BASEURL/drops/drops.roa \
	$BASEURL/drops/drops.mft \
	$BASEURL/drops/drops.crl"
for r in $REMOVALS; do
	# Find file ID of the $r URL
	FILEID=$(jq -r ".rrdp.files | to_entries[] | [.key, .value.uri] | @tsv" \
		"$SANDBOX/../step$STEP_PREV/workdir/https/1.json" |
		awk "{ if (\$2 == \"$r\") print \$1 }" -)

	check_logfile fort2 -F "TRC: rm -f https/1/$FILEID"
done
