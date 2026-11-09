#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/invalid.asa: The Provider ASIDs are not listed in ascending order."

check_vrps
check_aspas
