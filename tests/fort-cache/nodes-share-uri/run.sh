#!/bin/sh

. "tools/checks.sh"
. "rp/$RP.sh"

# Step 1

run_barry
run_rp
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"

# Step 2

cp "$SANDBOX/workdir/https/1.json" "$SANDBOX/workdir/https/2.json"
cp -r "$SANDBOX/workdir/https/1" "$SANDBOX/workdir/https/2"

run_rp
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"

URI="https://localhost:8443/nodes-share-uri/notification.xml"
# TODO sometimes swaps the jsons because of the random directory traversal
check_logfile fort2 -F "WRN: https/1.json and https/2.json are both identified by URI '$URI'. Dropping both."
check_logfile fort2 -F "TRC: rm -f https/1.json"
check_logfile fort2 -F "TRC: rm -rf https/1"
check_logfile fort2 -F "TRC: rm -f https/2.json"
check_logfile fort2 -F "TRC: rm -rf https/2"

# Both 1 and 2 are distrusted, so deleted.
# The cage is redownloaded into 3.
test -f "$SANDBOX/workdir/https/3.json" \
	-a -d "$SANDBOX/workdir/https/3" \
	-a ! -f "$SANDBOX/workdir/https/1.json" \
	-a ! -d "$SANDBOX/workdir/https/1" \
	-a ! -f "$SANDBOX/workdir/https/2.json" \
	-a ! -d "$SANDBOX/workdir/https/2" || fail "Unexpected cache files"

ACTUAL="$(jq -r ".uri" "$SANDBOX/workdir/https/3.json")"
test "$ACTUAL" = "$URI" || fail "The URI of cage $SANDBOX/workdir/https/3.json is '$ACTUAL', not '$URI'"
