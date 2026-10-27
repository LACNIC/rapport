#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp --rsync.enabled="false"

check_logfile fort2 -F "TRE: Certificate validation failed: CRL signature failure"

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"
