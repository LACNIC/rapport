#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Certificate is missing the 'CRL Distribution Points' extension"

check_vrps
