#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Basic Constraints extension contains a Path Length Constraint"

check_vrps
