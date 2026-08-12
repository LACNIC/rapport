#!/bin/sh

# Issue #189: RRDP snapshot duplicate publish URI — regression guard
#
# When an RRDP snapshot contains two <publish> elements for the same URI,
# Fort MUST reject the snapshot (RRDP desync detection, RFC 9697). This
# test injects a duplicate <publish> entry into the snapshot and verifies
# that Fort:
#   1. Detects the duplicate and rejects the snapshot
#   2. Falls back to rsync and recovers with the clean repository
#   3. Produces the correct VRP set from the rsync-served objects
#
# Two sub-tests exercise both orderings of the duplicate entries to ensure
# detection is order-independent:
#   T1 (A then B): A's entry first, B's second
#   T2 (B then A): B's entry first, A's appended
#
# In both cases, Fort must reject the RRDP snapshot and fall back to rsync,
# producing only B's VRP (AS64520) from the clean rsync tree.
#
# History: before the fix, Fort processed duplicates silently with
# last-write-wins semantics. T1 was the regression guard — Fort accepted
# VRP_B by accident (B overwrote A on disk, manifest matched B's hash).
# Now both sub-tests pass: the snapshot is rejected regardless of order.


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

run_rp

# Fort rejects the RRDP snapshot (duplicate URI detected) and falls back to
# rsync. The rsync tree has B's clean objects -> VRP for B only.
check_vrps "1.1.0.0/24-24 => AS64520"

# Confirm the desync detection fired.
check_logfile fort2 -E "RRDP desync: <publish> is attempting to create '.*', but the file is already cached\."


# ---------------------------------------------------------------------------
# T1: A then B — B overwrites A on disk; manifest matches B (current BUG)
# ---------------------------------------------------------------------------

# Use a new session ID so Fort does a full resync rather than reusing T2's
# cached RRDP state (which recorded a manifest failure for this RPP).
new_step
run_barry "rd_b2"

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

run_rp

# Same assertion: Fort rejects the snapshot, falls back to rsync, B's VRP only.
check_vrps "1.1.0.0/24-24 => AS64520"

# Confirm the desync detection fired.
check_logfile fort2 -E "RRDP desync: <publish> is attempting to create '.*', but the file is already cached\."


rm -f /tmp/roa_a.b64
