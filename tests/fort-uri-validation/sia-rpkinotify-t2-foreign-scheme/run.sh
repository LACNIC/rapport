#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "Unknown scheme"

check_vrps
