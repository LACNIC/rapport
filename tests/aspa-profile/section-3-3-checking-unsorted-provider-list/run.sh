#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "The Provider ASIDs are not listed in ascending order."

check_vrps
check_aspas

stop_rp