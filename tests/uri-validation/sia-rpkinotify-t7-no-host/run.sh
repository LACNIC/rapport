#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "TRE: Cannot parse GENERAL_NAME 'https:///$TEST/notification-ca.xml' as a URI: Protocol disallows empty host"

check_vrps
