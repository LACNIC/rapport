#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Parent certificate doesn't own ASN range '1-100'"

check_vrps
