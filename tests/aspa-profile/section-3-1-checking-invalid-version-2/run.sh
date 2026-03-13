#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Version number is not 1: 2"
# TODO Add rpki-client, prover & routinator
