#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_report fort1       -F "The OID of the SignedObject's encapContentInfo is not 'aspa'."
# TODO Add rpki-client, prover & routinator
