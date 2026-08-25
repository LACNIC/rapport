#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Extension 'SIA' lacks a 'rpkiManifest' valid rsync URI"

check_vrps
