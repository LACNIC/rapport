#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
run_rp

check_vrps \
	"10.0.0.0/24-24 => AS64496" \
	"10.0.1.0/24-24 => AS64496"

new_step
create_delta rd2
run_rp

check_vrps \
	"10.0.0.0/24-24 => AS64496" \
	"10.0.1.0/24-24 => AS64496"