#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Found an unexpected IP Resources extension."

check_vrps
check_aspas
