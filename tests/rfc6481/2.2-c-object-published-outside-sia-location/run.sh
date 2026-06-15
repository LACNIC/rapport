#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1: Establish a known-good cache (shared baseline for both sub-tests).
# ---------------------------------------------------------------------------

run_barry rd1
run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"


# ---------------------------------------------------------------------------
# Step 2: caRepository SIA of ca.cer points to wrong-ca/.
# fort follows the SIA, finds no manifest there, fails the fetch for ca.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp

# Validator attempts to retrieve the manifest of ca from wrong-ca/ 
# (the URI declared in the CA cert's SIA) and finds nothing there.
check_logfile fort1 -F "Manifest missing."

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"4.1.0.0/24-24 => AS40001" \
	"4.1.1.0/24-24 => AS40001"

# ---------------------------------------------------------------------------
# Step 3: probe-roa.roa has its EE cert SIA.signedObject set
# to wrong-location.roa; ca.cer itself has the correct caRepository SIA.
# Validator must reject only probe-roa, accepting all other objects in ca/.
# ---------------------------------------------------------------------------

new_step
create_delta rd3

run_rp

# Validator detects that the URI in the EE cert's SIA.signedObject does not match
# the URI from which it retrieved probe-roa.roa.
check_logfile fort1 -F "Certificate's signedObject ("

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"