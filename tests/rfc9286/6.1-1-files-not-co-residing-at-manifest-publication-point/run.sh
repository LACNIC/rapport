#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
run_rp

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001"

new_step
create_delta rd2
run_rp

check_logfile fort2 -E "RPP rsync://[^ ]+ does not directly contain manifest rsync://[^ ]+\."

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001"
