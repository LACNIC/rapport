#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp --rsync.enabled="false"

# TODO It's not a certificate
check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ca/ca.crl: Certificate is missing the 'Authority Key Identifier' extension."

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"
