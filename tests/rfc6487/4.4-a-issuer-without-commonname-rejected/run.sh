#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "The 'issuer' name has an unknown attribute"

check_vrps
