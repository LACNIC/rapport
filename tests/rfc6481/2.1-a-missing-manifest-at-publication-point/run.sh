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
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"


# ---------------------------------------------------------------------------
# Step 2: introduce ca3, then remove its manifest from the rsync tree.
# ---------------------------------------------------------------------------

new_step
run_barry rd2

# Remove ca3's manifest from the rsync publication point.
rm "sandbox/rsyncd/content/$TEST/ca3/ca3.mft"

run_rp "--http.enabled=false"

# The validator must warn about the missing manifest in ca3's publication point.
check_logfile fort2 -F "Manifest missing: rsync://localhost:8873/rpki/$TEST/ca3/ca3.mft"

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"1.1.4.0/24-24 => AS10001" \
	"1.1.5.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001"
