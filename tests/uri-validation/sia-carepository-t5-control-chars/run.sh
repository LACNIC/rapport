#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: Cannot parse GENERAL_NAME 'rsync://localhost:8873/rpki/$TEST/c\\ta' as a URI: Illegal character in path component"
# TODO Haven't figured out how to transfer the control char correctly
touch "$SANDBOX/.disable-post-log-checks"
