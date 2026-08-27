#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# issues#178 and issues#181.
# Fort behavior seems compliant, but the spec itself seems questionable.
# WONTFIX for now. Will come back to this after Fort 2.0.
# Related:
# - rfc6481/2.2-c-object-published-outside-sia-location-ca 
# - rfc9286/6.2-1-manifest-unreachable-via-sia-uri and
test "$RP" = "fort2" && skip

run_barry rd1
run_rp

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001"

new_step
create_delta rd2
run_rp

check_logfile fort2 -E "RPP rsync://[^ ]+ does not directly contain manifest rsync://[^ ]+\."

check_vrps \
	"1.1.0.0/24-24 => AS10001" \
	"1.1.1.0/24-24 => AS10001" \
	"1.1.2.0/24-24 => AS10001" \
	"1.1.3.0/24-24 => AS10001"
