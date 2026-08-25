#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "The Subject Public Key's hash does not match the AKI"

check_vrps