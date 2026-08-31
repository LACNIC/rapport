#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "maxLength (33) is out of bounds (0-32)"

check_vrps
