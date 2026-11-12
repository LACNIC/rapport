#!/bin/sh

# Issue #190: Failed RRDP delta can remove a previous-good object and drop its VRP
#
#   P0 (baseline): route.roa present, VRP_A accepted.
#   C2 (control):  delta fails (invalid base64 publish, NO withdraw of route.roa)
#                  + snapshot 404 + rsync disabled. VRP_A must remain.

. tools/checks.sh
. rp/$RP.sh

APACHEDIR="$APACHE2_DIR/content/$TEST"
NOTIFICATION="$APACHEDIR/notification.xml"
SNAPSHOT="$APACHEDIR/snapshot.xml"

# ---------------------------------------------------------------------------
# P0 — Baseline: valid repository with route.roa, VRP_A present
# ---------------------------------------------------------------------------

run_barry rd_step1-p0
run_rp

check_vrps "1.1.0.0/24-24 => AS64510"

new_step

# ---------------------------------------------------------------------------
# C2 — Control: invalid publish, NO withdraw of route.roa + snapshot 404
# ---------------------------------------------------------------------------

# rd_c2 adds extra.roa alongside the unchanged route.roa.
create_delta "rd_step2-c2"

# The base64 of the publish from extra.roa is corrupted in a valid delta.
DELTA_C2="$APACHEDIR/delta-rd_step2-c2.xml"
sed -i ':a;N;$!ba;s|\(<publish uri="[^"]*extra\.roa">\)[^<]*\(</publish>\)|\1\nINVALID\n\2|' "$DELTA_C2"
NEWHASH=$(sha256sum "$DELTA_C2" | cut -d' ' -f1)
sed -i "s|\(<delta serial=\"2\" uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\" />\)|\1$NEWHASH\2|" "$NOTIFICATION"
rm -f "$SNAPSHOT"

run_rp "--rsync.enabled=false"

check_vrps "1.1.0.0/24-24 => AS64510"

check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/delta-rd_step2-c2.xml: Cannot decode base64: Generic error"
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/delta-rd_step2-c2.xml: Error requesting URL: Failure writing output to destination. (HTTP code: 200)"
check_logfile fort2 -F "TRE: https://localhost:8443/$TEST/snapshot.xml: Error requesting URL: The requested URL returned error: 404. (HTTP code: 404)"
