#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: Cannot parse GENERAL_NAME 'rsync://localhost:8873/rpki/$TEST/c\\xFF' as a URI: Illegal character in path component"
