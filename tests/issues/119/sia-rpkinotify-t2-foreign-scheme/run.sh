#!/bin/sh

# Issue #119 -- SIA rpkiNotify: foreign scheme (ftp://)
#
# RFC 6487 section 4.8.8.1 requires rpkiNotify to use rsync:// scheme.
# A certificate advertising ftp:// as rpkiNotify is profile-invalid
# and must be rejected. Its descendant ROA must not produce a VRP.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -E "URI '[^']*' does not begin with 'rsync://'"
check_logfile fort1 -F "Extension 'SIA' lacks a 'rpkiNotify' valid rsync URI."
