#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspas "16842752:[1]"

stop_rp