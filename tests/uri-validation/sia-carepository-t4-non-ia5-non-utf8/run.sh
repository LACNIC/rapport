#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort2 -F "TRE: Cannot parse GENERAL_NAME 'rsync://localhost:8873/rpki/sia-carepository-t4-non-ia5-non-utf8/c\\xFF' as a URI: Illegal character in path component"
