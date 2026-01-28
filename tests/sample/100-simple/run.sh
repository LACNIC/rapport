#!/bin/sh

# Among a few others, all tests inherit the following environment variables:
#
# - $TEST: Name of the test (in this case, "100-simple")
# - $CATEGORY: Category of the test (in this case, "sample")
# - $TESTID: "$CATEGORY/$TEST" (in this case, "sample/100-simple")
# - $SRCDIR: Path to the test's source directory ("tests/sample/100-simple").
#   This directory contains all the (constant) files that will build and run
#   the test, which is this script (run.sh) plus (usually) some Barry RDs.
# - $SANDBOX: Path to the test's sandbox ("sandbox/tests/sample/100-simple"),
#   which is supposed to be its workspace. Here, the test can dump temporal
#   files and output, and is the place the user needs to be directed to if
#   debugging needs to take place.
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
run_barry


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
