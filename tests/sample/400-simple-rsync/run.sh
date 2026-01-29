#!/bin/sh

# This sample test shows one way to disable RRDP,
# which forces the RP to fall back to rsync.
# The validation run is meant to succeed.

. tools/checks.sh
. rp/$RP.sh


# In accordance to its documentation,
# Barry produces no RRDP files if --rrdp-uri is empty.
# Also, empty --rrdp-path results in nonexistent rpkiNotify SIAS,
# ensuring the RP will not even attempt RRDP.
run_barry "rd" --rrdp-uri "" --rrdp-path ""
run_rp


# No HTTP requests should be received, some rsync requests should be received.
check_http_requests
check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"


# In spite of RRDP's absence, the validation should succeed via rsync.
check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234"
