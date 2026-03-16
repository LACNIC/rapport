#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_aspa_output "16842752:[13001,70001,80001]"
