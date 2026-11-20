#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"
run_rp --rsync.enabled=false

check_vrps \
	"101:101:100::/40-40 => AS1234" \
	"101:102::/32-32 => AS1234" \
	"101:201:100::/40-40 => AS1234" \
	"101:202::/32-32 => AS1234" \
	"101:300::/24-24 => AS1234" \
	"102:100::/24-24 => AS1234" \
	"103::/16-16 => AS1234" \
	"201::/16-16 => AS1234" \
	"300::/8-8 => AS1234"
check_aspas

# Step 2
# b.cer's RPP is lost, so it's fallbacked.
# c.cer's RPP is not lost, but it's forced to be fallbacked.

new_step
create_delta "rd2"
#rm -rf "$APACHE2_PATH/content/$TEST/b"
#echo "1" > "$APACHE2_DIR/content/$TEST/b/notification.xml"
run_rp --rsync.enabled=false

check_vrps \
	"101:101:100::/40-40 => AS1234" \
	"101:102::/32-32 => AS1234" \
	"101:201:100::/40-40 => AS1234" \
	"101:202::/32-32 => AS1234" \
	"101:300::/24-24 => AS1234" \
	"152:100::/24-24 => AS1234" \
	"153::/16-16 => AS1234" \
	"5201::/16-16 => AS1234" \
	"5300::/8-8 => AS1234"
check_aspas

check_logfile fort2 -F "TRE: rsync://localhost:8873/rpki/$TEST/b1/b1.mft: The SignerInfo version is only allowed to be 3. (Was 0.)"
check_logfile fort2 -F "TRC: Fallbackness inherited."
