#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_aspas "1:[8,9]"
