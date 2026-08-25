#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Certificate lacks both IP and AS extension"

check_vrps
