#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "CA certificate has the 'Extended Key Usage' extension"

check_vrps
