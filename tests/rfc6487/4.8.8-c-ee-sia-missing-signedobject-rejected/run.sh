#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRE: Extension 'SIA' lacks a 'signedObject' valid rsync URI."

check_vrps
