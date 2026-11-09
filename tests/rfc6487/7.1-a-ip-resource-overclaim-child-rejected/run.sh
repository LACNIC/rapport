#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/parent/child.cer: Parent certificate doesn't own IPv4 prefix '2.0.0.0/16'."

check_vrps
