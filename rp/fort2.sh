#!/bin/sh

# The default string that invokes the RP's binary, which is supposed to work in
# most environments.
# Like other programs, RPs add themselves to $PATH during installation, so this
# is usually just the basename of the binary.
# If the RP is not actually in $PATH, the user can override this default by
# setting the corresponding environment variable (in this case, $FORT).
export RP_BIN_DEFAULT="fort"

# Name of the environment variable that overrides $RP_BIN_DEFAULT.
export RP_EV="FORT"

# $MEMCHECK's default value. (See the README.)
export MEMCHECK_DEFAULT=1

# Will be invoked to check the binary's existence.
# Must cause the RP to return zero and exit as soon as possible.
rp_test() {
	$RP_BIN -V > /dev/null
}

rp_run() {
	$VALGRIND $RP_BIN \
		--mode standalone \
		--tal "$TAL" \
		--local-repository "$WORKSPACE/workdir" \
		--report "$WORKSPACE/report.txt" \
		> "$WORKSPACE/$RP.log" 2>&1
}

rp_tal() {
	echo "$WORKSPACE/$TEST.tal"
}

# A callback for the most basic test.
# It's the RP-dependent part of it, so all RPs need to override it.
# Prints the number of VRPs the RP generated.
rp_count_vrps() {
	# TODO Prometheus would be a more formal means to extract this
	grep -x -- "INF: - Valid ROAs: .*" "$WORKSPACE/$RP.log" | cut -d' ' -f5
}
