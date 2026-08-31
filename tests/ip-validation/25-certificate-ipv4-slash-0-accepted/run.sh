#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps "192.0.2.0/24-24 => AS64512"
