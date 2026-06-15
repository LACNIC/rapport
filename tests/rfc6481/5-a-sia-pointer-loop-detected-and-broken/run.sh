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
# The validator must detect the situation and prevent an infinite 
# validation loop.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp

# TODO: This only covers the case of FORT
# The validator follows cycle-ca's caRepository SIA to ca1/ and the referenced manifest.
# Issuer validation prevents the infinite loop from executing.
check_logfile fort2 -E "Issuer name \('[0-9a-f]+'\) does not equal issuer certificate's name \('[0-9a-f]+'\)\."

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"