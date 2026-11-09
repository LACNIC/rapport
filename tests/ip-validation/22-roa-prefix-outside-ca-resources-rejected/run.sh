#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/route.roa: ROA is not allowed to advertise 10.0.0.0/24."

check_vrps
