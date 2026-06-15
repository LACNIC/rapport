#!/bin/sh

# Test 4b: two-manifests-coexist-during-key-rollover
#
# RFC 6481, section 2.2 states that in cases of key rollover, both the old and
# new CA instances SHOULD continue to publish into the same repository publication
# point during the transition window. The shared publication point will therefore
# contain CRLs, manifests, and subordinate products from both CA instances
# simultaneously. Section 4 further requires that the subordinate products of the
# old CA instance be eventually overwritten by those of the new CA instance,
# completing the rollover.
#
# This test verifies that the validator correctly handles all three phases of an
# RFC 6481-compliant key rollover:
#
#   Phase 1 — pre-rollover (step 1, rd1):
#     Only the old CA instance (ca-old) exists, publishing into its own
#     publication point. A known-good baseline cache is established.
#
#   Phase 2 — coexistence (step 2, rd2):
#     Both ca-old and ca-new publish into the same shared publication point.
#     The shared directory contains two manifests (ca-old.mft and ca-new.mft)
#     and two CRLs (ca-old.crl and ca-new.crl). The validator must:
#       - Associate each manifest with its correct CA instance using the
#         id-ad-rpkiManifest SIA URI in each CA certificate.
#       - Process the two manifests independently, without cross-contamination.
#       - Accept VRPs from both CA instances simultaneously.
#
#   Phase 3 — transition complete (step 3, rd3):
#     ca-old is removed from ta's manifest. Only ca-new remains in the shared
#     publication point, along with its products. The validator must:
#       - Cleanly retire the VRPs originating from ca-old (they are no longer
#         reachable from the trust anchor, so no failed-fetch fallback applies).
#       - Accept all new VRPs issued by ca-new.
#
# Test structure (3 steps, RRDP + rsync):
#
#   Step 1 (rd1): ca-old publishes in ca-old/ with valid-old-1.roa and
#                 valid-old-2.roa. VRPs established from ca-old only.
#
#   Step 2 (rd2): ca-old moves to shared/; ca-new appears in shared/ as well.
#                 Two manifests and two CRLs coexist in the shared publication
#                 point. VRPs from both ca-old and ca-new are expected.
#
#   Step 3 (rd3): ca-old removed from ta.mft; shared/ contains only ca-new
#                 products, plus a new ROA (valid-new-2.roa). VRPs from ca-old
#                 must be absent; VRPs from ca-new must all be present.

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
# ca-old's products are gone from the shared publication point.
# The validator must retire ca-old's VRPs cleanly (no failed-fetch fallback,
# since ca-old is no longer reachable from the trust anchor).
# ---------------------------------------------------------------------------

new_step
create_delta rd3
run_rp

check_vrps \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001"