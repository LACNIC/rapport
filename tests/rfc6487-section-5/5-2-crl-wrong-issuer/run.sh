#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -E "Issuer name \('WrongIssuer'\) does not equal issuer certificate's name \('[^']*'\)\."
check_logfile fort2 -F "Bad manifest."

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"
