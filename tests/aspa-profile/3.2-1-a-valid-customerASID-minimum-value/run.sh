#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRC: Adding ASPA for customer 16842752"

check_vrps
check_aspas "16842752:[1000]"
