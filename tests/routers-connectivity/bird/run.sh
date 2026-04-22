#!/bin/sh

. tools/checks.sh
. rp/$RP.sh
. router/bird.sh

run_barry
start_rp

bird_start
    
bird_validate_ipv4_prefixes \
    "1.1.0.0" "16" "16" "1234" \
    "1.2.0.0" "16" "16" "1234"

bird_validate_ipv6_prefixes \
    "101::" "16" "16" "1234" \
    "102::" "16" "16" "1234"

bird_validate_aspa \
    "5:[15001, 15002, 15003, 15004, 15005]" \
    "2:[13001, 13002, 13003]"
 
bird_stop

stop_rp