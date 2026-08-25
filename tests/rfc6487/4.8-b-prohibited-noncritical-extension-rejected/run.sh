#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "Ignoring unknown non-critical extension"

check_vrps \
        "1.1.0.0/24-24 => AS64512"
 