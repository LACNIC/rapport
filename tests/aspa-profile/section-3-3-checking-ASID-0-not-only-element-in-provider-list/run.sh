#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Provider ASID '0' is not in a single item list."
# TODO Add rpki-client, prover & routinator
