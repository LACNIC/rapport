#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRE: Cannot parse GENERAL_NAME 'rsync:///rpki/$TEST/ca' as a URI: Protocol disallows empty host"
