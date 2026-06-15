#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# ---------------------------------------------------------------------------
# Step 1 — Pre-rollover: only ca-old exists in its own publication point.
# ---------------------------------------------------------------------------

run_barry rd1
run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001"

# ---------------------------------------------------------------------------
# Step 2 — Coexistence: ca-old and ca-new share the same publication point.
# The shared directory holds two manifests and two CRLs simultaneously.
# The validator must process each manifest independently via its CA's SIA.
# ---------------------------------------------------------------------------

new_step
create_delta rd2
run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"

# ---------------------------------------------------------------------------
# Step 3 — Transition complete: ca-old removed; ca-new is the sole CA.
# ca-old's objects are gone from the shared publication point.
# The validator must retire ca-old's VRPs cleanly.
# ---------------------------------------------------------------------------

new_step
create_delta rd3
run_rp

check_vrps \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001"