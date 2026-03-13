#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Too many providers: 4001 > 4000"
# TODO Add rpki-client, prover & routinator
