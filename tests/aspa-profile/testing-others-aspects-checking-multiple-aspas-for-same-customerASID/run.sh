#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "aspa1A.asa: Adding ASPA for customer 10"
check_logfile fort1 -F "aspa1B.asa: Adding ASPA for customer 10"
check_logfile fort1 -F "aspa1C.asa: Adding ASPA for customer 20"
check_logfile fort1 -F "aspa1D.asa: Adding ASPA for customer 10"

check_vrps
check_aspas \
    "10:[10001,10002,10003,10004,10005,10006,10007,10008,10009,10010]" \
    "20:[20001,20002]"

stop_rp