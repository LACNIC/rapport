#!/bin/sh

# Issue #119 -- SIA rpkiManifest: wrong scheme (https:// instead of rsync://)
#
# RFC 6487 section 4.8.8.1 requires rpkiManifest to use rsync:// scheme.
# A certificate advertising https:// as rpkiManifest is profile-invalid
# and must be rejected. Its descendant ROA must not produce a VRP.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -E "URI '[^']*' does not begin with 'rsync://'"
check_logfile fort1 -F "Extension 'SIA' lacks a 'rpkiManifest' valid rsync URI."
