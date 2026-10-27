#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Illegal key usage flag string: 000001000"

check_vrps
