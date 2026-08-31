#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps "1.1.2.1/32-32 => AS64512"
