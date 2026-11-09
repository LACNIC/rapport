#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: Cannot parse GENERAL_NAME 'https://localhost:8443/$TEST/notificat\\tion-ca.xml' as a URI: Illegal character in path component"
# TODO Haven't figured out how to transfer the control char correctly
touch "$SANDBOX/.disable-post-log-checks"

check_vrps
