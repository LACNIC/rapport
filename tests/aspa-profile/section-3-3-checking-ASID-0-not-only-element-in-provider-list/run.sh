#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Provider ASID '0' is not in a single item list."

check_vrps
check_aspas

stop_rp