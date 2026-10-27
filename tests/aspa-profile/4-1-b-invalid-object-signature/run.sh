#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp


# Output contains libcrypto error stack
touch "$SANDBOX/.disable-log-checks"

check_vrps
check_aspas "2:[13001,70001,80001]"
