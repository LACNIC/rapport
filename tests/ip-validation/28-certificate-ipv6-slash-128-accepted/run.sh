#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps "2001:db8::1/128-128 => AS64512"
