#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

test "$RP" = "fort2" || skip "Test is FORT2-specific"

export APACHE2_PORT="8444"
export APACHE2_DIR="sandbox/apache2/$APACHE2_PORT"
tools/apache2-start.sh "$SRCDIR/apache2.conf"

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

check_logfile fort2 -F "TRE: https://localhost:$APACHE2_PORT/$TEST/notification.xml: Redirecting to https://attacker.invalid/$TEST/notification.xml; disallowing because of different origin."
# TODO turn this into a trace; it's nothing to worry about.
check_logfile fort2 -F "WRN: Cannot traverse through https/1: No such file or directory"
