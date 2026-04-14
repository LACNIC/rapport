#!/bin/sh

. tools/checks.sh
. rp/$RP.sh
. router/frr.sh

run_barry rd1
start_rp


frr_load_and_restart
sleep 5
    

frr_validate_prefix_table \
    "1.1.1.0" "24" "24" "13001" \
    "1.1.0.0" "24" "24" "13001" \
    "1.1.2.0" "24" "24" "13002"
 
 frr_stop
 stop_rp