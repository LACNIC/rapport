#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1: Establish a known-good cache.
# ---------------------------------------------------------------------------

run_barry rd1

run_rp "--http.enabled=false"

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"

# ---------------------------------------------------------------------------
# Step 2: Simulate mid-update inconsistency on ca's publication point.
# ca2 is left consistent and must have its new VRPs accepted.
# ---------------------------------------------------------------------------

new_step
run_barry rd2

rm "sandbox/rsyncd/content/$TEST/ca/valid-1-2.roa"

run_rp "--http.enabled=false"

# ca's fetch has failed (missing file listed in manifest).
check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001"

check_logfile fort1 -F "valid-1-2.roa' is absent from the cache."


# ---------------------------------------------------------------------------
# Step 3: The publication point reaches a consistent state.
# The validator must recover and import valid-1-2.roa.
# ---------------------------------------------------------------------------

new_step

# Barry regenerates rd2 in full, no files removed this time.
run_barry rd2

run_rp "--http.enabled=false"

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001"