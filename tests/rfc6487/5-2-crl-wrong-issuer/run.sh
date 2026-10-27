#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp --rsync.enabled="false"

check_logfile fort2 -F "TRE: Issuer name ('WrongIssuer') does not equal issuer certificate's name ('f8cd583b105acbecd0d3ab1a4a0fb7d49452c31d27f8d22336c2fdc4aad93dac')."

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"
