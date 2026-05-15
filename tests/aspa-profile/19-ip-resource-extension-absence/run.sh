#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Found an unexpected IP Resources extension."

check_vrps
check_aspas

stop_rp