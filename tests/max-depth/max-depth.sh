#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

case "$RP" in
	"fort2")
		MAXDEPTH_ARG="--maximum-certificate-depth 10"
		;;
	"routinator")
		MAXDEPTH_ARG="--max-ca-depth 10"
		;;
	"rpki-client")
		echo "Error: rpki-client seems to lack a maxdepth arg?"
		# It probably has a limit, but it's not configurable.
		# TODO Worry about it later.
		exit 1
		;;
	"rpki-prover")
		MAXDEPTH_ARG="--max-certificate-path-depth 10"
		;;
	*)
		echo "Test '$TEST' does not support $RP" 1>&2
		exit 1
		;;
esac

run_barry_default "$TEST.rd"
run_rp_default $MAXDEPTH_ARG

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
	"2.1.0.0/16-16 => AS1234" \
	"2.2.1.0/24-24 => AS1234" \
	"2.2.2.1/32-32 => AS1234" \
	"2.2.2.2/32-32 => AS1234"
check_http_requests \
	"/rrdp/ta.cer 200" \
	"/rrdp/notification.xml 200" \
	"/rrdp/notification.xml.snapshot 200"
check_rsync_requests
