#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "EE certificate's ASN extension does not exactly match customerASID 2."
# TODO Add rpki-client, prover & routinator
