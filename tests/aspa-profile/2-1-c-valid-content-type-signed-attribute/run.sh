#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspas \
        "16777216:[123,70000,4294967295]" \
        "33554432:[123,70000,4294967295]"
