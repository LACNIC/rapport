#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "TRC: Ignoring unknown non-critical extension: 1.2.3.4.5.6.7.8.9"

check_vrps \
        "1.1.0.0/24-24 => AS64512"
 
