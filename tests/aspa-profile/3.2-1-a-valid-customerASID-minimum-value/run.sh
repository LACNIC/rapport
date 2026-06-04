#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "aspa.asa: Adding ASPA for customer 1"

check_vrps
check_aspas "1:[1000]"