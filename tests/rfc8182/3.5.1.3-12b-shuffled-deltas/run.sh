#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"

run_rp
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/snapshot.xml 200"
check_rsync_requests

# Step 2

new_step
create_delta "rd2"

# Step 3

new_step
create_delta "rd3"

# Step 4

new_step
create_delta "rd4"

# Step 5

new_step
create_delta "rd5"

# Step 6

new_step
create_delta "rd6"

PFX="sandbox/apache2/8443/content/$TEST"
# <notification>, <snapshot />
head -5 "$PFX/notification.xml" > "$PFX/.notification.xml"
# <delta />s
grep -F "<delta" "$PFX/notification.xml" | shuf >> "$PFX/.notification.xml"
# </notification>
tail -1 "$PFX/notification.xml" >> "$PFX/.notification.xml"
mv "$PFX/.notification.xml" "$PFX/notification.xml"

run_rp
check_vrps \
	"1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234" \
	"2.0.0.0/8-8 => AS1234" "200::/8-8 => AS1234" \
	"3.0.0.0/8-8 => AS1234" "300::/8-8 => AS1234" \
	"4.0.0.0/8-8 => AS1234" "400::/8-8 => AS1234" \
	"5.0.0.0/8-8 => AS1234" "500::/8-8 => AS1234" \
	"6.0.0.0/8-8 => AS1234" "600::/8-8 => AS1234"
check_http_requests \
	"/$TEST/ta.cer 304" \
	"/$TEST/notification.xml 200" \
	"/3.5.1.3-12b-shuffled-deltas/delta-rd2.xml 200" \
	"/3.5.1.3-12b-shuffled-deltas/delta-rd3.xml 200" \
	"/3.5.1.3-12b-shuffled-deltas/delta-rd4.xml 200" \
	"/3.5.1.3-12b-shuffled-deltas/delta-rd5.xml 200" \
	"/3.5.1.3-12b-shuffled-deltas/delta-rd6.xml 200"
check_rsync_requests
