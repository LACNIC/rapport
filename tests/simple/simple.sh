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
run_barry_default "$TEST.rd"


# Step 2: Run the RP.
# I expect most tests will require a very similar single RP invocation,
# so I made this quick wrapper.
run_rp_default


# Step 3: Check the results.

# Here's a very typical check that should probably be defined for all tests:
# Check the RP's output VRP file lists the expected VRPs.
check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234"

# Check the RP made the logical sequence of HTTP requests.
check_http_requests \
	"/rrdp/ta.cer 200" \
	"/rrdp/notification.xml 200" \
	"/rrdp/notification.xml.snapshot 200"

# This is how you'd check the equivalent logical sequence of rysnc requests.
# (Since the RP will not have to fall back to rsync at any point, no requests
# are meant to be made here.)
#check_rsync_requests "rpki/"
