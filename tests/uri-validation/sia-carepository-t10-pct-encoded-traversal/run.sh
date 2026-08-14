#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

# Confirm the URI was normalized (no residual ".." or "//")
check_logfile fort2 -E "RPP rsync://localhost:8873(/[^/.)]+)* does not directly contain manifest"

# Confirm the traversal target was never written to the rsync cache.
if find "$SANDBOX/workdir/rsync" -path "*/etc/passwd" 2>/dev/null | grep -q .; then
    fail "Path traversal artifact found in rsync cache"
fi
