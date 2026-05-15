#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_logfile fort1 -F "EE certificate's ASN extension does not exactly match customerASID 2."

stop_rp