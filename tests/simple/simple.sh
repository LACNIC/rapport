#!/bin/sh

# Among a few others, all tests inherit the following environment variables:
#
# - $TEST: Name of the test (in this case, "simple")
# - $SRCDIR: Path to the test's source directory ("tests/simple").
#   This directory contains all the (constant) files that will build and run
#   the test (usually this script and likely a Barry RD).
# - $SANDBOX: Path to the test's sandbox directory ("sandbox/tests/simple"),
#   which is supposed to be its workspace. Here, the test will dump needed
#   temporal files and output, and is the place the user needs to be directed
#   if debugging needs to take place.
# - All the environment variables defined in the README.


# Import common checking functions.
# (Recall that this script is being run from ../../.)
. tools/checks.sh
# Import the RP's callbacks (which makes this portable).
. rp/$RP.sh


# Test scripts (like this one) need to return nonzero if an error was detected.
# The functions you get from tools/checks.sh take care of that automatically.
# If you define a custom check, remember to suffix it with
# `|| fail "error message"`.


# Step 1: Generate the test repository.
# I expect most tests will require a very similar single Barry invocation,
# so I made this quick wrapper.
run_barry "$TEST.rd"


# Step 2: Run the RP.
# I expect most tests will require a very similar single RP invocation,
# so I made this quick wrapper.
run_rp


# Step 3: Check the results.

# Here's a very typical check that should probably be defined for all tests:
# Verify the RP's output VRP file lists the expected VRPs.
check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234"

# Check the RP made the logical sequence of HTTP requests:
check_http_requests \
	"/$TEST/ta.cer 200" \
	"/$TEST/notification.xml 200" \
	"/$TEST/notification.xml.snapshot 200"

# Check the RP made the logical sequence of rsync requests
# (In this case, that would be none):
check_rsync_requests

# Check the cache files (Fort only)
check_fort_cache 0 1 1 3
check_fort_cache_file https
check_fort_cache_cage rrdp \
	"A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa" \
	"ta/A.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_file fallback
check_fort_cache_cage fallback "ta/A.cer" "ta/ta.crl" "ta/ta.mft"
check_fort_cache_cage fallback "A/A.crl" "A/A.mft" "A/A1.roa" "A/A2.roa"
