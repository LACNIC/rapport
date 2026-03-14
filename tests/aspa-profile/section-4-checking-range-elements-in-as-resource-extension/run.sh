#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "ASN extension is not allowed to contain 'range' elements."
# TODO Add rpki-client, prover & routinator
