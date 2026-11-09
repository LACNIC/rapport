#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/ca.cer: The 'issuer' name has an unknown attribute. (NID: 17)"

check_vrps
