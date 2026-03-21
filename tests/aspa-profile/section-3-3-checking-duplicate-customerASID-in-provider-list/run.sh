#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Provider ASID '13001' is listed more than once"

check_vrps
check_aspas

stop_rp