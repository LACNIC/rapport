#!/bin/sh

. tools/checks.sh
. rp/$RP.sh
. router/cisco.sh

run_barry
start_rp "for_cisco_test"
cisco_start
sleep 60

cisco_validate_ipv4_prefix \
    "1.1.0.0" "16" "16" "1234" \
    "1.2.0.0" "16" "16" "1234"

cisco_validate_ipv6_prefix \
    "101::" "16" "16" "1234" \
    "102::" "16" "16" "1234"

cisco_stop
stop_rp