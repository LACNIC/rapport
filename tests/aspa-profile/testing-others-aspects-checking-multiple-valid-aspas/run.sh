#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp


check_logfile fort1 -F "aspa1-1A.asa: Adding ASPA for customer 10"
check_logfile fort1 -F "aspa1-2A.asa: Adding ASPA for customer 20"
check_logfile fort1 -F "aspa2-1A.asa: Adding ASPA for customer 21"
check_logfile fort1 -F "aspa2-1B.asa: Adding ASPA for customer 22"
check_logfile fort1 -F "aspa2-1C.asa: Adding ASPA for customer 23"
check_logfile fort1 -F "aspa2-1D.asa: Adding ASPA for customer 24"
check_logfile fort1 -F "aspa3A.asa: Adding ASPA for customer 45"
check_logfile fort1 -F "aspa4A.asa: Adding ASPA for customer 65"
check_logfile fort1 -F "aspa4B.asa: Adding ASPA for customer 70"
check_logfile fort1 -F "aspa5A.asa: Adding ASPA for customer 85"

check_vrps
check_aspas \
	"10:[10001,10002]" \
	"20:[20001,20002]" \
    "21:[21001,21002]" \
    "22:[22001,22002]" \
    "23:[23001,23002]" \
    "24:[24001,24002]" \
    "45:[45001,45002]" \
    "65:[65001,65002]" \
    "70:[70001,70002]" \
    "85:[85001,85002]"

stop_rp