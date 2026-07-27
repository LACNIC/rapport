#!/bin/sh

# Issue #119 -- SIA rpkiNotify: missing host (rsync:///path)
#
# A valid rsync URI requires a host component (rsync://host/path).
# rsync:///path (empty host) is malformed and must be rejected by Fort
# before attempting to use it as a repository location.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps
