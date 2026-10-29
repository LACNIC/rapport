#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

check_logfile fort2 -F "TRC: URI 'ftp://localhost:8873/rpki/sia-rpkimanifest-t2-foreign-scheme/ca/ca.mft': Unknown scheme"
check_logfile fort2 -F "TRE: Extension 'SIA' lacks a 'rpkiManifest' valid rsync URI."
