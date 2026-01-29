#!/bin/sh

# Compared to 200-bad-roa-version, this sample test targets a somewhat more
# complicated repository tree.
# 
# The tree is not inherently flawed, but it exceeds the maximum certificate
# chain length the RP is told to accept.

. tools/checks.sh
. rp/$RP.sh

# The maximum allowed depth often depends on configuration,
# and different RPs tend to ship with different defaults.
# Hence, we need to send a custom argument to the RP.
case "$RP" in
	"fort2")
		MAXDEPTH_ARG="--maximum-certificate-depth 13"
		;;
	"routinator")
		MAXDEPTH_ARG="--max-ca-depth 11"
		;;
	"rpki-client")
		MAXDEPTH_ARG="" # Hardcoded
		;;
	"rpki-prover")
		MAXDEPTH_ARG="--max-certificate-path-depth 12"
		;;
	*)
		fail "Test '$TEST' does not support $RP"
		;;
esac

run_barry
# run_rp() proxies its (optional) arguments to the RP,
# to customize its run according to the test's needs.
# (run_barry() also does it.)
run_rp $MAXDEPTH_ARG

check_report fort2       -F "Certificate chain maximum depth exceeded."
check_report rpki-client -F "maximum certificate chain depth exhausted"
# TODO Add prover & routinator

check_vrp_output \
	"1.0.0.0/8-8 => AS1234" \
	"100::/8-8 => AS1234" \
	"201::/16-16 => AS1234" \
	"202:100::/24-24 => AS1234" \
	"202:201::/32-32 => AS1234" \
	"202:202:100::/40-40 => AS1234" \
	"202:202:201::/48-48 => AS1234" \
	"202:202:202:100::/56-56 => AS1234" \
	"202:202:202:201::/64-64 => AS1234" \
	"202:202:202:202:100::/72-72 => AS1234" \
	"202:202:202:202:201::/80-80 => AS1234" \
	"202:202:202:202:202:100::/88-88 => AS1234" \
	"202:202:202:202:202:201::/96-96 => AS1234" \
	"2.1.0.0/16-16 => AS1234" \
	"2.2.1.0/24-24 => AS1234" \
	"2.2.2.1/32-32 => AS1234" \
	"2.2.2.2/32-32 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"
check_rsync_requests
