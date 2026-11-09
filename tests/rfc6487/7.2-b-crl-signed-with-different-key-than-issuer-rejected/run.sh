#!/bin/sh


. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp --rsync.enabled="false"

# TODO Awkward error message
check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/ca.mft: Certificate validation failed: CRL signature failure"

check_vrps
