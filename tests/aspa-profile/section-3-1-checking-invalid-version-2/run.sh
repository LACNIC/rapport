#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Version number is not 1: 2"

check_vrps
check_aspas

stop_rp