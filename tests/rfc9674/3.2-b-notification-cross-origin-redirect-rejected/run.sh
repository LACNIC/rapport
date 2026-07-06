#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/apache2-redirect.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"


# Runs no matter how this script exits (normal end, fail()'s exit 1, or any
# unexpected error) so a single shared Apache instance is always left running
# for whichever test runs next.
trap restore_normal_apache EXIT


# Apache instance swap: throwaway redirect-capable instance for this test only
start_redirect_apache

run_barry
run_rp

check_vrps \
	"101::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"2.1.0.0/16-16 => AS1234"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 302"

check_rsync_requests \
	"rpki/"

check_logfile fort2 -E "https?://[^ ]+ is redirecting to https?://[^ ]+; disallowing because of different origin\."
