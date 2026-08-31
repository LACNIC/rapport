#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Prefix length (32) > maxLength (16)"

check_vrps
