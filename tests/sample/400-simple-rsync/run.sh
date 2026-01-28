#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


run_barry "rd" --rrdp-uri "" --rrdp-path ""
run_rp


# Step 3: Check the results.

# Here's a very typical check that should probably be defined for all tests:
# Verify the RP's output VRP file lists the expected VRPs.
check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234"

check_http_requests
check_rsync_requests \
	"rpki/$TEST/ta.cer" \
	"rpki/"

# Check the cache files (Fort only)
#check_fort_cache 0 1 1 3
#check_fort_cache_file https
#check_fort_cache_cage rrdp \
#	"A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa" \
#	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"
#check_fort_cache_file fallback
#check_fort_cache_cage fallback "ta/A.cer" "ta/ta.crl" "ta/ta.mft"
#check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa"
