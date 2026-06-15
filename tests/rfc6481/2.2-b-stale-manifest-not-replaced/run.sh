#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1: Establish a known-good cache.
# ---------------------------------------------------------------------------

run_barry rd1

run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"

# ---------------------------------------------------------------------------
# Step 2: ca's manifest was not replaced and is now stale.
# ca2 and ca3 have fresh manifests and must be processed normally.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp

check_logfile fort1 -F "Manifest is stale."
check_logfile fort1 -F "Bad manifest."

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001" \
	"4.1.0.0/24-24 => AS40001" \
	"4.1.1.0/24-24 => AS40001"