#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

# libcrypto needs CRLDP for certificate type identification.
# Fort currently ignores certificates with unrecognized types.
# So Fort is presently ignoring (rather than rejecting) certificates with
# multiple CRLDPs.
# In practice, the result is the same, sans error message.
# That said, it's concerning that X509_check_purpose() is not rejecting the
# multiple CRLDPs, given that's a violation of rfc5280#section-4.2.
# But whatever... This is acceptable for now. The resolution of #178 (#181)
# might later change this expected outcome.

#check_logfile fort2 -E "The CRL Distribution Points extension has 2 distribution points\. \(1 expected\)"
check_logfile fort2 -F "Unrecognized certificate type; Ignoring."

check_vrps
