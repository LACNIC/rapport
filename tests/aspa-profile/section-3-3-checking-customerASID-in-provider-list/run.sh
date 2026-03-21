#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "The Providers list contains the customer's ASID"

check_vrps
check_aspas

stop_rp