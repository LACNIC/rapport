#!/bin/sh

. tools/checks.sh
. rp/$RP.sh
. router/frr.sh

run_barry
start_rp

frr_load_and_restart
sleep 5
    
frr_validate_prefix_table \
    "1.1.0.0" "16" "16" "1234" \
    "1.2.0.0" "16" "16" "1234" \
    "101::" "16" "16" "1234" \
    "102::" "16" "16" "1234"
 
 frr_reset

 stop_rp