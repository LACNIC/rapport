#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Too many providers: 4001 > 4000"

check_vrps
check_aspas

stop_rp