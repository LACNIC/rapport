#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: Invalid IA5String character: 0xc3"

check_vrps
