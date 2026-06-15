#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# ---------------------------------------------------------------------------
# Step 1: Baseline with RRDP active.
# Confirms the RP uses RRDP as its primary access method when rpkiNotify
# is present in the SIA.
# ---------------------------------------------------------------------------

run_barry rd1
run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"

check_rsync_requests


# ---------------------------------------------------------------------------
# Step 2: rsync is the only available access method.
# Barry generates rd2 without rpkiNotify SIA entries and without RRDP files.
# The RP must use rsync exclusively; validation must succeed.
# ---------------------------------------------------------------------------

new_step
run_barry rd2 --rrdp-uri "" --rrdp-path ""

run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"2.1.4.0/24-24 => AS20001" \
	"2.1.5.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001"

check_http_requests

check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"


# ---------------------------------------------------------------------------
# Step 3: RRDP is advertised but unavailable; RP falls back to rsync.
# Barry generates rd3 with RRDP active, then all RRDP files are removed.
# The RP must detect the RRDP failure and retrieve all objects via rsync.
# ---------------------------------------------------------------------------

new_step
run_barry rd3

# Remove all RRDP content, simulating an RRDP server outage.
rm -rf "sandbox/apache2/content/$TEST/"*

run_rp

check_vrps \
	"2.1.0.0/24-24 => AS20001" \
	"2.1.1.0/24-24 => AS20001" \
	"2.1.2.0/24-24 => AS20001" \
	"2.1.3.0/24-24 => AS20001" \
	"2.1.4.0/24-24 => AS20001" \
	"2.1.5.0/24-24 => AS20001" \
	"2.1.6.0/24-24 => AS20001" \
	"2.1.7.0/24-24 => AS20001" \
	"3.1.0.0/24-24 => AS30001" \
	"3.1.1.0/24-24 => AS30001" \
	"3.1.2.0/24-24 => AS30001" \
	"3.1.3.0/24-24 => AS30001" \
	"3.1.4.0/24-24 => AS30001" \
	"3.1.5.0/24-24 => AS30001"

check_http_requests \
	"/$TEST/ta.cer 404" \
	"/$TEST/notification.xml 404"

check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"