#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRC: Adding ASPA for customer 16908288"

check_vrps
check_aspas "16908288:[2000]"
