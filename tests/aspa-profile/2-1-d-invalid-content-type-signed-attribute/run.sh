#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspas "16777216:[123,70000,4294967295]"

check_report fort1 -F "The OID of the SignedObject's content type attribute is not 'aspa'."