#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# rsync is the only available access method.
# Barry generates rd without rpkiNotify SIA entries and without RRDP files.
# The RP must use rsync exclusively; validation must succeed.
# ---------------------------------------------------------------------------

run_barry rd --rrdp-uri "" --rrdp-path ""
run_rp

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"

check_http_requests

check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"
