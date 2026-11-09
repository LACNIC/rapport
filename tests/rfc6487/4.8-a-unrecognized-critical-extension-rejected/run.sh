#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: Certificate has unknown critical extension: 1.2.3.4.5.6.7.8.9"

check_vrps
