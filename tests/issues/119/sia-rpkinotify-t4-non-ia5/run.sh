#!/bin/sh

# Issue #119 -- SIA rpkiNotify: non-IA5 character (accented 'á' in path)
#
# RFC 6487 section 4.8.8.1 requires the rpkiNotify URI to be an IA5String.
# IA5String allows only a subset of ASCII (code points 0x00-0x7F).
# A URI containing characters outside that range (e.g. U+00E1 'á') is
# profile-invalid. Fort must reject the certificate without attempting
# to convert the non-ASCII character into a filesystem path.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -F "URL has non-printable character code"
