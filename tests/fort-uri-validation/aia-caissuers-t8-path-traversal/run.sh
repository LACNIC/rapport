#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--http.enabled=false"

check_vrps

# Confirm the URI was normalized (no residual ".." or "//")
check_logfile fort2 -E "Certificate's caIssuers \(rsync://localhost:8873(/[^/.)]+)*\) does not match any of the TAL's rsync URIs."

# Confirm the traversal target was never written to the rsync cache.
if find "$SANDBOX/workdir/rsync" -path "*/etc/passwd" 2>/dev/null | grep -q .; then
    fail "Path traversal artifact found in rsync cache"
fi