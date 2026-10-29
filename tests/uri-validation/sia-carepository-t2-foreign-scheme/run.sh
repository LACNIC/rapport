#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRC: URI 'ftp://localhost/rpki/sia-carepository-t2-foreign-scheme/ca': Unknown scheme"
check_logfile fort2 -F "TRE: Extension 'SIA' lacks a 'caRepository' valid rsync URI."
