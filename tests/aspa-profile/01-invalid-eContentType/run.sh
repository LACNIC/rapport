#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "The OID of the SignedObject's encapContentInfo is not 'aspa'."

check_vrps
check_aspas

stop_rp