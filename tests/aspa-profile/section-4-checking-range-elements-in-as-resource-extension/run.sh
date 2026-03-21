#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "ASN extension is not allowed to contain 'range' elements."

check_vrps
check_aspas

stop_rp