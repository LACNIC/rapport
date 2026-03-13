#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "The Providers list contains the customer's ASID"
# TODO Add rpki-client, prover & routinator
