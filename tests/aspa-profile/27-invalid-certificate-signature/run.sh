#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp


check_logfile fort1 -F "Certificate validation failed: certificate signature failure"

check_vrps
check_aspas "2:[13001,70001,80001]"

stop_rp