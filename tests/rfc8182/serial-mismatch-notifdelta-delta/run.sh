#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"
run_rp --rsync.enabled="false"
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"

# Step 2

new_step
create_delta "rd2"
sed -i"" 's/serial="2">/serial="1">/' "$APACHE2_DIR/content/$TEST/delta-rd2.xml"
HASH="$(sha256sum "$APACHE2_DIR/content/$TEST/delta-rd2.xml" | cut -d' ' -f1)"
sed -i"" "s/delta-rd2.xml\" hash=\".*\"/delta-rd2.xml\" hash=\"$HASH\"/" \
	"$APACHE2_DIR/content/$TEST/notification.xml"
run_rp --rsync.enabled="false"

check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/delta-rd2.xml: (Line 4) Delta serial '1' does not match Notification serial '2'"
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/delta-rd2.xml: Error requesting URL: Failure writing output to destination. (HTTP code: 200)"
check_logfile fort2 -F "TRC: Falling back to snapshot."
check_logfile fort2 -F "TRC: RPP seems salvageable."
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234"
# TODO Add other checks
