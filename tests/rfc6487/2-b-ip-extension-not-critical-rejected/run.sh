#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Extension 'IP Resources' is supposed to be marked critical"

check_vrps
