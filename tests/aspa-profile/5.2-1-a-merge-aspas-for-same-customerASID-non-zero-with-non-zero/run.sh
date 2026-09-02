#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "aspa-1.asa: Adding ASPA for customer 10"
check_logfile fort1 -F "aspa-2.asa: Adding ASPA for customer 10"

check_vrps
check_aspas \
    "10:[64512,64513,64514,64515]"
