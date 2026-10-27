#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1

run_rp --rsync.enabled="false"

check_vrps \
    "1.1.0.0/24-24 => AS10001" \
    "1.1.1.0/24-24 => AS10001" \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001"

new_step
create_delta "rd2"
run_rp --rsync.enabled="false"

check_logfile fort2 -E "TRE: RPP rsync://localhost:8873/rpki/$TEST/ca does not directly contain manifest rsync://localhost:8873/rpki/nonexistent/ca.mft"

check_vrps \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001" \
    "3.1.0.0/24-24 => AS30001" \
    "3.1.1.0/24-24 => AS30001"
