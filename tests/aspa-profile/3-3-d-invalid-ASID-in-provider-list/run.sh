#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

# TODO Maybe shouldn't be called "valid"
check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/valid.asa: Provider out of range. (0-4294967295)"

check_vrps
check_aspas
