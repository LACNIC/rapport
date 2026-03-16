#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_aspas "16842752:[4294967294]"

