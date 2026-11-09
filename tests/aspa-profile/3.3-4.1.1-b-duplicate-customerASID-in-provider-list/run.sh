#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/invalid.asa: Provider ASID '13001' is listed more than once."

check_vrps
check_aspas
