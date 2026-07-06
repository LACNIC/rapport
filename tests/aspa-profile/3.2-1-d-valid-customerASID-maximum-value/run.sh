#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "aspa.asa: Adding ASPA for customer 4294967295"

check_vrps
check_aspas "4294967295:[65001]"
