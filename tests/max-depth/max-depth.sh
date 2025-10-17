#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

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

run_barry "$TEST.rd"
run_rp $MAXDEPTH_ARG

check_report fort2       -F "Certificate chain maximum depth exceeded."
check_report rpki-client -F "maximum certificate chain depth exhausted"
# TODO prover & routinator

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
