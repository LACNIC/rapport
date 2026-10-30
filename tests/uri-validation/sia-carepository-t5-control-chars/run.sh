#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRE: Cannot parse GENERAL_NAME 'rsync://localhost:8873/rpki/sia-carepository-t5-control-chars/c\\ta' as a URI: Illegal character in path component"
# TODO Haven't figured out how to transfer the control char correctly
touch "$SANDBOX/.disable-post-log-checks"
