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
# Step 2: caRepository SIA of ca.cer points to wrong-ca/.
# fort follows the SIA, finds no manifest there, fails the fetch for ca.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp

# Validator attempts to retrieve the manifest of ca from wrong-ca/ 
# (the URI declared in the CA cert's SIA) and finds nothing there.
check_logfile fort2 -E "RPP rsync://[^ ]+ does not directly contain manifest rsync://[^ ]+\."

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"
