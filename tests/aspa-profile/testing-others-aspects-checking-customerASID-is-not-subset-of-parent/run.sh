#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Certificate validation failed: RFC 3779 resource not subset of parent's resources"
# TODO Add rpki-client, prover & routinator