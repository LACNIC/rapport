#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1

run_rp

check_vrps \
    "1.1.0.0/24-24 => AS10001" \
    "1.1.1.0/24-24 => AS10001" \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001"

new_step
create_delta "rd2"

run_rp

check_vrps \
    "1.1.0.0/24-24 => AS10001" \
    "1.1.1.0/24-24 => AS10001" \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001" \
    "3.1.0.0/24-24 => AS30001" \
    "3.1.1.0/24-24 => AS30001"

check_report fort2 -F "New manifestNumber (1) is not higher than fallback manifestNumber (1)."
