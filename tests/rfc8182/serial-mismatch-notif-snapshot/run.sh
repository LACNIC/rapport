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
# Remove the delta from the notification, to force the resnapshot.
sed -i"" 's/<delta.*>//' "$APACHE2_DIR/content/$TEST/notification.xml"
run_rp --rsync.enabled="false"

# First attempts to delta up, fails, then rejects the Snapshot too.
check_logfile fort2 -F "TRW: https://localhost:8443/$TEST/notification.xml: There's no delta list to process."
check_logfile fort2 -F "TRC: Falling back to snapshot."
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/snapshot.xml: (Line 4) Snapshot serial '1' does not match Notification serial '2'"
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/snapshot.xml: Error requesting URL: Failure writing output to destination. (HTTP code: 200)"
check_logfile fort2 -F "TRC: Refresh failed."
# rsync disabled, so succeeds on the fallback.
check_logfile fort2 -F "TRC: It's already a fallback."
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"
# TODO Add other checks
