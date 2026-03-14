#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Customer 0 is not allowed..."
# TODO Add rpki-client, prover & routinator