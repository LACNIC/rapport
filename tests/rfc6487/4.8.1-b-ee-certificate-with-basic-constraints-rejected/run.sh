#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Certificate has unknown critical extension: 2.5.29.19"

check_vrps
