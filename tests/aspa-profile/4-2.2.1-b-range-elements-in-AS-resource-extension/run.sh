#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: ASN extension is not allowed to contain 'range' elements."

check_vrps
check_aspas
