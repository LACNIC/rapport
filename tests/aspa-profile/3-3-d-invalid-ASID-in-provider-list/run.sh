#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Provider out of range. (0-4294967295)"

check_vrps
check_aspas
