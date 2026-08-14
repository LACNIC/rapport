#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "Illegal character in path component"
check_logfile fort2 -F "Extension 'AIA' lacks a 'caIssuers' valid rsync URI."
