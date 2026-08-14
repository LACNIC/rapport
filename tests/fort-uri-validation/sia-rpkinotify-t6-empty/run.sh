#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "Cannot parse GENERAL_NAME '' as a URI"

check_vrps
