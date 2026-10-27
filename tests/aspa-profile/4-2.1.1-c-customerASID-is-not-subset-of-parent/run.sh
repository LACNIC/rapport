#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Parent certificate doesn't own ASN range '1-1'."

check_vrps
check_aspas
