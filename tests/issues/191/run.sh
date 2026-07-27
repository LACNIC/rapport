#!/bin/sh

# Issue #191 -- target (T1): child CA's AIA caIssuers URI is syntactically
# valid but does NOT identify its actual immediate superior certificate
# (parent.cer) -- it points to an unrelated, unreachable location instead.
# Per RFC 6487 4.8.7, the singular id-ad-caIssuers accessLocation is
# expected to identify the actual immediate superior certificate; a CA
# whose caIssuers reference does not do so is profile-invalid, and its
# subtree should not be accepted as a source of valid VRPs.
#
# Regression guard: check_vrps with no arguments asserts ZERO VRPs. This
# FAILS while the bug exists (Fort accepts the child CA anyway and still
# emits the descendant ROA's VRP), and PASSES once Fort validates the
# caIssuers URI against the actual parent certificate used in the chain.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
