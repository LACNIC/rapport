#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "Provider out of range. (0-4294967295)"
