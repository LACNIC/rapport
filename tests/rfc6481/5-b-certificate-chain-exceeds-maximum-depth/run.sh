#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd

MAXDEPTH_ARG="--maximum-certificate-depth 6"
run_rp $MAXDEPTH_ARG

check_report fort2 -F "Certificate chain maximum depth exceeded."

check_vrps \
	"10.0.1.0/24-24 => AS10001" \
	"10.0.2.0/24-24 => AS10001" \
	"10.1.0.0/24-24 => AS10001" \
	"10.1.1.0/24-24 => AS10001" \
	"10.1.2.0/24-24 => AS10001" \
	"10.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"