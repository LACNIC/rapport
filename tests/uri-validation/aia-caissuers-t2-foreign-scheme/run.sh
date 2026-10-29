#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRC: URI 'ftp://localhost/rpki/aia-caissuers-t2-foreign-scheme/ta.cer': Unknown scheme"
check_logfile fort2 -F "TRE: Extension 'AIA' lacks a 'caIssuers' valid rsync URI."
