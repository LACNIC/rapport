#!/bin/sh

# This sample test is a negative counterpart of "100-simple". It targets a
# small repository that happens to be flawed in a small way.
# 
# The repository's only ROA violates the following requirement from RFC 6482:
# 
# > The version number of the RouteOriginAttestation MUST be 0.
# 
# Though future manifest specifications might define profiles for versions other
# than zero, it is (seemingly) generally accepted that validators today are
# supposed to discard such objects.


. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrp_count 0

# Check the RP rejected the object for the intended reason,
# by querying its output.
# The error message is not standardized, of course,
# so each RP needs a dedicated check.
check_report fort2       -F "ROA's version (2) is nonzero."
check_report rpki-client -F "unexpected version (expected 0, got 2)"
# TODO Add prover & routinator

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
