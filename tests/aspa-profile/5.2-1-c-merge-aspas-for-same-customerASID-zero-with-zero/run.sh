#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRC: Adding ASPA for customer 10"
check_logfile fort2 -F "TRC: Adding ASPA for customer 10"

check_vrps
check_aspas \
    "10:[0]"
