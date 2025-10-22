#!/bin/sh

# Among a few others, all tests inherit the following environment variables:
#
# - $TEST: Name of the test (in this case, "simple")
# - $SANDBOX: Path to the test's sandbox directory ("sandbox/tests/simple"),
#   which is supposed to be its workspace. Here, the test will dump needed
#   temporal files and output, and is the place the user needs to be directed
#   if debugging needs to take place.
# - All the environment variables defined in the README.


# Import common checking functions.
# (Recall that this script is being run from ../../.)
. tools/checks.sh


# Test scripts (like this one) need to return nonzero if an error was detected.
# The functions you get from tools/checks.sh take care of that automatically.
# If you define a custom check, remember to suffix it with
# `|| fail "error message"`.


# ==== Run the RP ====
$RP_BIN	-c "routinator.conf" -vv vrps \
	> "$SANDBOX/vrps.csv" \
	2> "$SANDBOX/stderr.txt" \
	|| fail "Routinator returned $?. (See sandbox/tests/simple/routinator.log)"


# ==== Check the results ====

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
