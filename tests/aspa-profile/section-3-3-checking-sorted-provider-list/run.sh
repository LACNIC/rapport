#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_aspa_output "16842752:[13000,13001,65001,65002,80001,80002,90005,102500,102501,102502]"
