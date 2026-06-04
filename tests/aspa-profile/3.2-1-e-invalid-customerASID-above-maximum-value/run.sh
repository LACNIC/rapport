#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry

# This is a patch. 
# Because in order to evaluate the scenario, 
# the asum range extension must be overridden in the TA, 
# which causes FORT to return a code 22, 
# having not been able to correctly validate any TAL.
# Therefore any FORT error is ignored,
# partially evaluating ASN validation out of bounds.

( run_rp ) 2>>"$SANDBOX/ignored-errors.log" || true

check_logfile fort1 -F "ta.cer: ASN value '4294967296' is out of bounds."