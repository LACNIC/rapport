#!/bin/sh

# Issue #190: Failed RRDP delta can remove a previous-good object and drop its VRP
#
#   P0 (baseline): route.roa present, VRP_A accepted.
#   T1 (target):   valid withdraw of route.roa, then invalid publish fails,
#                  + snapshot 404 + rsync disabled. VRP_A absent (bug).
#                  Regression guard: check_vrps FAILS while bug exists.

. tools/checks.sh
. rp/$RP.sh

APACHEDIR="sandbox/apache2/content/$TEST"
NOTIFICATION="$APACHEDIR/notification.xml"
SNAPSHOT="$APACHEDIR/snapshot.xml"

# ---------------------------------------------------------------------------
# P0 — Baseline: valid repository with route.roa, VRP_A present
# ---------------------------------------------------------------------------

run_barry rd_step1-p0
run_rp

check_vrps "1.1.0.0/24-24 => AS64510"

new_step

# --------------------------------------------------------------------------------------
# T1 — Target: valid withdraw of route.roa + invalid publish of extra.roa + snapshot 404
# --------------------------------------------------------------------------------------

# rd_step2-t1 removes route.roa and introduces extra.roa. Barry-delta generates:
#   <withdraw uri="...route.roa" hash="CORRECT_HASH"/>  <- valid, applied first
#   <publish  uri="...extra.roa">BASE64</publish>       <- corrupted below
create_delta rd_step2-t1

DELTA_T1="$APACHEDIR/delta-rd_step2-t1.xml"
sed -i ':a;N;$!ba;s|\(<publish uri="[^"]*extra\.roa">\)[^<]*\(</publish>\)|\1\nINVALID\n\2|' "$DELTA_T1"
NEWHASH=$(sha256sum "$DELTA_T1" | cut -d' ' -f1)
sed -i "s|\(<delta serial=\"2\" uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\" />\)|\1$NEWHASH\2|" "$NOTIFICATION"
rm -f "$SNAPSHOT"

run_rp "--rsync.enabled=false"

# Regression guard: asserts VRP_A IS present (correct behavior after fix).
# FAILS while the bug exists: withdraw committed, no rollback, VRP_A absent.
check_vrps "1.1.0.0/24-24 => AS64510"
