#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRE: Cannot parse GENERAL_NAME 'rsync://localhost:8873/rpki/$TEST/t\\xFFa.cer' as a URI: Illegal character in path component"
