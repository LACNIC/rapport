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
sed -i"" 's/<delta serial="2"/<delta serial="1"/' "sandbox/apache2/content/$TEST/notification.xml"
run_rp --rsync.enabled="false"

# Rejects the entire Notification.
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/notification.xml: Notification serial does not match highest delta serial: 2 != 1"
# rsync disabled, so succeeds on the fallback.
check_logfile fort2 -F "TRC: It's already a fallback."
# TODO Add other checks
