#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2       -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/aspa.asa: ASN extension is not allowed to contain 'inherit' elements."

check_vrps
check_aspas
