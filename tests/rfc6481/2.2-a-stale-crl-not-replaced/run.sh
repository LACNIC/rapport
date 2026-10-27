#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1: Establish a known-good cache.
# ---------------------------------------------------------------------------

run_barry rd1

run_rp --rsync.enabled="false"

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"

# ---------------------------------------------------------------------------
# Step 2: ca's CRL has not been replaced; it is now stale.
# ca2 and ca3 have valid CRLs and must be processed normally.
# ---------------------------------------------------------------------------

new_step
create_delta rd2

run_rp --rsync.enabled="false"

check_logfile fort2 -F "TRE: CRL is stale/expired. (lastUpdate:2019-12-01 00:00:00Z, nextUpdate:2020-01-01 00:00:00Z)"

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"
