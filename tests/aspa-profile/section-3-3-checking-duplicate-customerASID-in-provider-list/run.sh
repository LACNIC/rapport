#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Provider ASID '13001' is listed more than once"
# TODO Add rpki-client, prover & routinator

