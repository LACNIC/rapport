#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "The Provider ASIDs are not listed in ascending order."
# TODO Add rpki-client, prover & routinator
