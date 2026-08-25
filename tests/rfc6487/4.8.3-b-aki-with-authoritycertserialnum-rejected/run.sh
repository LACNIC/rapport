#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "The Authority Key Identifier contains an authorityCertSerialNumber."

check_vrps
