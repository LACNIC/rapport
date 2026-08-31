#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "ROA is not allowed to advertise 1.1.0.0/16"

check_vrps
