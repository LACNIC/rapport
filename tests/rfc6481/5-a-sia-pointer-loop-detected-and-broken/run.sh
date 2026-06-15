#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1: Establish a known-good baseline cache.
# ---------------------------------------------------------------------------

run_barry rd1
run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"

# ---------------------------------------------------------------------------
# Step 2: cycle-ca introduces a SIA pointer loop back to ca1/.
# The validator must detect the missing manifest and break the cycle.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp

# The validator follows cycle-ca's caRepository SIA to ca1/ and cannot find
# cycle-ca.mft there. It must emit a warning for the missing manifest.
check_logfile fort2 -F "Manifest missing."

# roa-cycle must NOT appear: cycle-ca's fetch failed.
# roa-valid and roa-ca1 must be accepted: unaffected by the cycle.
check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"