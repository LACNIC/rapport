#!/bin/sh

# Issue #119 -- SIA caRepository: foreign scheme (ftp://)
#
# RFC 6487 section 4.8.8.1 requires caRepository to use rsync:// scheme.
# A certificate advertising ftp:// as caRepository is profile-invalid
# and must be rejected. Its descendant ROA must not produce a VRP.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -E "URI '[^']*' does not begin with 'rsync://'"
check_logfile fort1 -F "Extension 'SIA' lacks a 'caRepository' valid rsync URI."
