#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
run_rp

check_vrps \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001" \
    "3.1.0.0/24-24 => AS30001" \
    "3.1.1.0/24-24 => AS30001"

new_step
create_delta "rd2"
run_rp

#check_logfile fort1 -F "file not-co-residing..."

check_vrps \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001" \
    "3.1.0.0/24-24 => AS30001" \
    "3.1.1.0/24-24 => AS30001" \
    "4.1.0.0/24-24 => AS40001" \
    "4.1.1.0/24-24 => AS40001"