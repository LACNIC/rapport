#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/invalid.asa: The Providers list contains the customer's ASID (16842752)."

check_vrps
check_aspas
