#!/bin/sh


. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Certificate validation failed: CRL signature failure"

check_vrps
