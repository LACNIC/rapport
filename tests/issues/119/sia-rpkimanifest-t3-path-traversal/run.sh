#!/bin/sh

# Issue #119 -- SIA rpkiManifest: path traversal (../ sequences in URI)
#
# A malicious certificate could embed ../ sequences in the rpkiManifest URI
# attempting to make Fort access filesystem paths outside its cache directory.
# Fort must reject this certificate before using the URI as a file path.
# Its descendant ROA must not produce a VRP.

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp
check_vrps

check_logfile fort1 -E "URI '[^']*' seems to be dot-dotting past its own domain."
