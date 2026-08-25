#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -E "The CRL Distribution Points extension has 2 distribution points\. \(1 expected\)"

check_vrps
