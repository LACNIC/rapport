#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort2 -F "IPv6 address has too many octets. (17)"

check_vrps
