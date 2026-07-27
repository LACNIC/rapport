#!/bin/sh

# Issue #189: RRDP snapshot duplicate publish URI order changes VRP output
#
# When an RRDP snapshot contains two <publish> elements for the same URI,
# Fort processes them sequentially and the last write wins. Changing only
# the order of those duplicate entries can change Fort's validated output:
#
#   T1 (A then B): B remains on disk; matches manifest for B (by accident)
#                  -> VRP_B accepted  <-- BUG: duplicate URI was silently accepted
#   T2 (B then A): A remains on disk; does not match manifest for B
#                  -> manifest hash mismatch -> no ROA VRP
#
# Expected behavior (correct fix): snapshots with duplicate <publish> URIs
# should be rejected before any snapshot-derived writes influence the
# repository state used for manifest validation.
#
# T2 asserts no ROA VRP, which coincidentally holds even with the current
# bug (manifest mismatch rejects the publication point).
# T1 asserts no ROA VRP and FAILS while the bug exists (Fort incorrectly
# accepts VRP_B), serving as the regression guard for the fix.
#
# rsync is disabled in both stages so there is no fallback to contaminate
# the assertions: we are testing RRDP snapshot processing in isolation.

. tools/checks.sh
. rp/$RP.sh

SNAPSHOT="sandbox/apache2/content/$TEST/snapshot.xml"
NOTIFICATION="sandbox/apache2/content/$TEST/notification.xml"


# ---------------------------------------------------------------------------
# Extract object A's signed bytes from a Barry-generated snapshot.
# No run_rp here: we only need A's base64-encoded content for injection.
# ---------------------------------------------------------------------------

run_barry "rd_a"

# Find route.roa's URI dynamically (Barry derives it from the tree + --rsync-uri).
ROA_URI=$(grep -o '<publish uri="[^"]*route\.roa"' "$SNAPSHOT" \
    | sed 's/<publish uri="//;s/"//')

# Extract the base64 body of ROA A (lines between its <publish> and </publish>).
# Write to a temp file to avoid shell-variable newline handling issues in awk.
# Use \|...|  as address delimiter because $ROA_URI contains '/' which sed
# would misinterpret as its default address delimiter.
sed -n "\|<publish uri=\"$ROA_URI\">|,\|</publish>|{
    \|<publish|d
    \|</publish>|d
    p
}" "$SNAPSHOT" > /tmp/roa_a.b64
 

# Generate the correct B repository: manifest references B's hash.
run_barry "rd_b"


# ---------------------------------------------------------------------------
# T2: B then A — A overwrites B on disk; manifest references B -> mismatch
# ---------------------------------------------------------------------------

# Append A's <publish> entry after B's in the snapshot (before </snapshot>).
# Barry's snapshot format: "  <publish uri="...">\nBASE64\n  </publish>\n</snapshot>\n"
sed -i 's|</snapshot>||' "$SNAPSHOT"
{
    printf '  <publish uri="%s">\n' "$ROA_URI"
    cat /tmp/roa_a.b64
    printf '  </publish>\n</snapshot>\n'
} >> "$SNAPSHOT"

# Recompute snapshot hash and update notification.
# Barry standalone uses no space before />: <snapshot uri="..." hash="..."/>
T2_HASH=$(sha256sum "$SNAPSHOT" | cut -d' ' -f1)
sed -i "s|\(<snapshot uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\"/>\)|\1$T2_HASH\2|" "$NOTIFICATION"

# Running FORT with rsync disabled to isolate RRDP snapshot processing.
run_rp "--rsync.enabled=false"

# T2: no ROA VRP expected.
# Current behavior: no VRP — A on disk doesn't match manifest for B.
# After fix: no VRP — snapshot rejected due to duplicate URI.
ck_inc
if grep -qE "AS64510|AS64520" "$SANDBOX/vrps.csv" 2>/dev/null; then
    fail "T2 (B then A): unexpected ROA VRP; snapshot with duplicate URI should be rejected"
fi


# ---------------------------------------------------------------------------
# T1: A then B — B overwrites A on disk; manifest matches B (current BUG)
# ---------------------------------------------------------------------------

# Use a new session ID so Fort does a full resync rather than reusing T2's
# cached RRDP state (which recorded a manifest failure for this RPP).
new_step
run_barry "rd_b"

# Insert A's <publish> entry BEFORE B's entry so B is processed last
# and ends up on disk (matching the manifest). This is the order that
# triggers the bug: the snapshot is structurally invalid (duplicate URI)
# yet Fort accepts it and produces VRP_B.
LINE=$(grep -Fn "<publish uri=\"$ROA_URI\"" "$SNAPSHOT" | head -n1 | cut -d: -f1)
test -n "$LINE" || fail "No se encontró <publish uri=\"$ROA_URI\"> en $SNAPSHOT"

BLOCK="/tmp/publish_a_block.xml"
{
    printf '  <publish uri="%s">\n' "$ROA_URI"
    cat /tmp/roa_a.b64
    printf '  </publish>\n'
} > "$BLOCK"

sed "$((LINE - 1))r $BLOCK" "$SNAPSHOT" > "${SNAPSHOT}.tmp" && mv "${SNAPSHOT}.tmp" "$SNAPSHOT"
rm -f "$BLOCK"

# Change session to "beef" to force a full RRDP resync.
sed -i 's/session_id="cafe"/session_id="beef"/' "$SNAPSHOT"
sed -i 's/session_id="cafe"/session_id="beef"/' "$NOTIFICATION"

# Recompute snapshot hash after the injection and session change.
T1_HASH=$(sha256sum "$SNAPSHOT" | cut -d' ' -f1)
sed -i "s|\(<snapshot uri=\"[^\"]*\" hash=\"\)[0-9a-f]*\(\"/>\)|\1$T1_HASH\2|" "$NOTIFICATION"

# Running FORT with rsync disabled to isolate RRDP snapshot processing.
run_rp "--rsync.enabled=false"

# T1: no ROA VRP expected (same assertion as T2).
# Current behavior (BUG): VRP_B present — B on disk, manifest matches by accident.
# After fix: no VRP — snapshot rejected due to duplicate URI.
# This assertion FAILS while the bug exists, acting as the regression guard.
ck_inc
if grep -qE "AS64510|AS64520" "$SANDBOX/vrps.csv" 2>/dev/null; then
    fail "T1 (A then B): ROA VRP present; snapshot with duplicate URI was silently accepted (issue #189)"
fi

rm -f /tmp/roa_a.b64
