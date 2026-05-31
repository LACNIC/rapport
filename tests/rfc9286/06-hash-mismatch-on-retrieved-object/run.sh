#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1

run_rp "--http.enabled=false"

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
    "3.1.0.0/24-24 => AS30001" \
    "3.1.1.0/24-24 => AS30001"

new_step
create_delta "rd2"

truncate -s 1m "sandbox/rsyncd/content/$TEST/ca/valid-1-2.roa"

run_rp "--http.enabled=false"

check_logfile fort1 -F "'valid-1-2.roa' does not match its expected hash"

check_vrps \
    "2.1.0.0/24-24 => AS20001" \
    "2.1.1.0/24-24 => AS20001" \
    "3.1.0.0/24-24 => AS30001" \
    "3.1.1.0/24-24 => AS30001" \
    "4.1.0.0/24-24 => AS40001" \
    "4.1.1.0/24-24 => AS40001"