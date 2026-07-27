#!/bin/sh

# Issue #119 -- IAI caIssuers: empty URI
#
# RFC 6487 section 4.8.8.1 requires the caIssuers accessLocation to be a
# non-empty rsync:// URI identifying the CA's publication directory.
# An empty string is not a valid URI by any definition (RFC 3986 section 3
# requires at minimum a scheme component).

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -F "URI '' does not begin with 'rsync://'."
check_logfile fort1 -F "Extension 'AIA' lacks a 'caIssuers' valid rsync URI."

