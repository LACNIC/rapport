#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# Step 1

run_barry "rd1"
run_rp

# Step 2

new_step
create_delta "rd2"

# A publish without a hash is supposed to add the file.
# A publish with a hash is supposed to replace the file.
# This publish lacks a hash, but the cache already has a.roa, from rd1.
BOGUS_PUBLISH="<publish uri=\"rsync://localhost:8873/rpki/$TEST/ta/a.roa\">ZmFpbAo=</publish>"
sed -i"" "s#serial=\"2\">#serial=\"2\">$BOGUS_PUBLISH#" "$APACHE2_DIR/content/$TEST/delta-rd2.xml"

run_rp

check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/delta-rd2.xml: (Line 4) RRDP desync: <publish> is attempting to create 'rsync://localhost:8873/rpki/$TEST/ta/a.roa', but the file is already cached."
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/delta-rd2.xml: Error requesting URL: Failure writing output to destination. (HTTP code: 200)"
