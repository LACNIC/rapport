#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

# libcrypto needs BC for certificate type identification.
# Fort currently ignores certificates with unrecognized types.
# So Fort is presently ignoring (rather than rejecting) certificates lacking BC.
# In practice, the result is the same, sans error message.
# This is fine for now. The resolution of #178 (#181) might later change this
# expected outcome.

#check_logfile fort2 -F "Certificate is missing the 'Basic Constraints' extension"
check_logfile fort2 -F "Unrecognized certificate type; Ignoring."

check_vrps
