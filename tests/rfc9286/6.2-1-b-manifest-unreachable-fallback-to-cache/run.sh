#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# Step 1: establish a known-good cache.
# ---------------------------------------------------------------------------
run_barry rd1
run_rp "--http.enabled=false"

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"

# ---------------------------------------------------------------------------
# Step 2: introduce ca3, then remove ca2 manifest from the rsync tree.
# ---------------------------------------------------------------------------

new_step
run_barry rd2

# Remove ca2's manifest from the rsync publication point. 
# In this case, the validator is simulated as being unable 
# to retrieve the manifest of a CA that is already cached.
rm "sandbox/rsyncd/content/$TEST/ca2/ca2.mft"

run_rp "--http.enabled=false"

# Fort doesn't print anything because the compare-dest rsync is blind to the
# manifest removal.
# There are tests elsewhere that check corrupted manifest fallbacks,
# so there's probably not much else to check.
#check_logfile fort2 -F "TRE: Manifest missing: rsync://localhost:8873/rpki/$TEST/ca2/ca2.mft"

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"
