#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_aspa_output "1:[8,9]"
