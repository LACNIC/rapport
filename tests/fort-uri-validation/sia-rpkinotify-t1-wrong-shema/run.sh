#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "Ignoring non-https rpkiNotify"

check_vrps
