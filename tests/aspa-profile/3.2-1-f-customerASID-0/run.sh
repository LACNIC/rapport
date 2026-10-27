#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Customer 0 is not allowed."

check_vrps
check_aspas
