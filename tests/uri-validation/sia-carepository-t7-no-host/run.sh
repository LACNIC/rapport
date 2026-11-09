#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: Cannot parse GENERAL_NAME 'rsync:///rpki/$TEST/ca' as a URI: Protocol disallows empty host"
