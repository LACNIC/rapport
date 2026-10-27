#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Prefix length (24) > maxLength (20)"

check_vrps