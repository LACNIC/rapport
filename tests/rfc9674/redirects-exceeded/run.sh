#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

export APACHE2_PORT="8446"
export APACHE2_DIR="sandbox/apache2/$APACHE2_PORT"
tools/apache2-start.sh "$SRCDIR/apache2.conf"

run_barry
run_rp

check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"

check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 302" \
	"/$TEST/step 302"

check_rsync_requests \
	"rpki/"

check_logfile fort2 -F "TRC: Attempting redirect: https://localhost:8446/redirects-exceeded/step"
check_logfile fort2 -F "TRC: Attempting redirect: https://localhost:8446/redirects-exceeded/snapshot.xml"
check_logfile fort2 -F "TRE: https://localhost:8446/redirects-exceeded/notification.xml: Too many redirects."
check_logfile fort2 -F "WRN: Cannot traverse through https/1: No such file or directory"
