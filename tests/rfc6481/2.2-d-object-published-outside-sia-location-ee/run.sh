#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1: Establish a known-good cache (baseline).
# ---------------------------------------------------------------------------

run_barry rd1
run_rp

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"

# ---------------------------------------------------------------------------
# Step 2: probe-roa.roa has its EE cert SIA.signedObject set
# to wrong-location.roa; ca.cer itself has the correct caRepository SIA.
# Validator must reject only probe-roa, accepting all other objects in ca/.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp

# Validator detects that the URI in the EE cert's SIA.signedObject does not match
# the URI from which it retrieved probe-roa.roa.
check_logfile fort2 -E "Certificate's signedObject \('[^']+'\) does not match the URI of its own signed object \([^)]+\)\."

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"
