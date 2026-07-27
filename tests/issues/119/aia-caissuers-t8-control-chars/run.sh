#!/bin/sh

# Issue #119 -- AIA caIssuers: control character (tab) embedded in URI
#
# URIs must not contain raw control characters (RFC 3986 section 2.4).
# A tab character (0x09) embedded in the caIssuers URI path is invalid.
# Fort must reject the certificate without using the malformed URI as a
# filesystem path, since control characters could affect path resolution
# depending on the underlying OS and filesystem implementation.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -F "URL has non-printable character code"
