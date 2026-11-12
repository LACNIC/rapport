#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

export APACHE2_PORT="8445"
export APACHE2_DIR="sandbox/apache2/$APACHE2_PORT"
tools/apache2-start.sh "$SRCDIR/apache2.conf"

run_barry
run_rp

check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 302" \
	"/$TEST/snapshot.xml 200"

check_rsync_requests \
	"rpki/"

check_logfile fort2 -F "TRC: Attempting redirect: https://localhost:8445/$TEST/snapshot.xml"
check_logfile fort2 -F "TRE: https://localhost:8445/$TEST/notification.xml: The document was not an RRDP Notification."
# TODO ...
check_logfile fort2 -F "WRN: Cannot traverse through https/1: No such file or directory"
