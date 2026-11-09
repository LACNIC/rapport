#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps
check_aspas "16777216:[123,70000,4294967295]"

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/ta/bad-signerInfo.asa: The OID of the SignedObject's content type attribute is not 'aspa'."
