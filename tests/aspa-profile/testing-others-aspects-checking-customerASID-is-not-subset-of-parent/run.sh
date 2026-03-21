#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "Certificate validation failed: RFC 3779 resource not subset of parent's resources"

check_vrps
check_aspas

stop_rp