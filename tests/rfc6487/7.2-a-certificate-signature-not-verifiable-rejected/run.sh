#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Certificate validation failed: certificate signature failure"

check_vrps \
	"1.1.0.0/16-16 => AS50"