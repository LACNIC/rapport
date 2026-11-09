#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp


check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/invalid.asa: Certificate validation failed: certificate signature failure"

check_vrps
check_aspas "2:[13001,70001,80001]"
