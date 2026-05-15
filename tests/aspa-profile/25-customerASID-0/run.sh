#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Customer 0 is not allowed..."

check_vrps
check_aspas

stop_rp