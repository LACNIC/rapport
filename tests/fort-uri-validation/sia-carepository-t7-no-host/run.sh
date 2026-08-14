#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "Protocol disallows empty host"
check_logfile fort2 -F "Extension 'SIA' lacks a 'caRepository' valid rsync URI."
