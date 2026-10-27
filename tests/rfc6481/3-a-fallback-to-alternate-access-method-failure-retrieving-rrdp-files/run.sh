#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# RRDP is advertised but unavailable; RP falls back to rsync.
# Barry generates rd with RRDP active, then all RRDP files are removed.
# The RP must detect the RRDP failure and retrieve all objects via rsync.
# ---------------------------------------------------------------------------

run_barry rd

# Remove all RRDP content, simulating an RRDP server outage.
rm -rf "sandbox/apache2/content/$TEST/"*

run_rp

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001" \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001"

check_http_requests \
	"/$TEST/ta.cer 404" \
	"/$TEST/notification.xml 404"

check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"

check_logfile fort2 -F "TRE: Error requesting URL: The requested URL returned error: 404. (HTTP code: 404)"
check_logfile fort2 -F "TRE: Error requesting URL: The requested URL returned error: 404. (HTTP code: 404)"
# TODO Probably shouldn't print these
check_logfile fort2 -F "WRN: Cannot traverse through https/0: No such file or directory"
check_logfile fort2 -F "WRN: Cannot traverse through https/1: No such file or directory"
