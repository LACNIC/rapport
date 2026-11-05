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
# This publish has a hash, but the cache doesn't have b.roa.
BOGUS_PUBLISH='<publish uri="rsync://localhost:8873/rpki/rrdp-misplaced-create/ta/b.roa" hash="2056a28ea38a000f3a3328cb7fabe330638d3258affe1a869e3f92986222d997">ZmFpbAo=</publish>'
sed -i"" "s#serial=\"2\">#serial=\"2\">$BOGUS_PUBLISH#" "sandbox/apache2/content/$TEST/delta-rd2.xml"

run_rp

check_logfile fort2 -F "TRE: (Line 4) RRDP desync: <publish> is attempting to overwrite 'rsync://localhost:8873/rpki/rrdp-misplaced-create/ta/b.roa', but the file is absent in the cache."
check_logfile fort2 -F "TRE: Error requesting URL: Failure writing output to destination. (HTTP code: 200)"
