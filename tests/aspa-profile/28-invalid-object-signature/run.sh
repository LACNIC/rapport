#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp


check_logfile fort1 -F "Signed Object's signature is invalid"

check_vrps
check_aspas "2:[13001,70001,80001]"

stop_rp