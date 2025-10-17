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

# `$RP_BIN $RP_TEST` will be invoked to check the binary's existence.
# $RP_TEST must be a flag that causes the RP to return zero as soon as possible.
export RP_TEST="-V"

# $MEMCHECK's default value. (See the README.)
export MEMCHECK_DEFAULT=1


# Typical, common, single-run RP invocation.
# $@: Additional arguments
rp_run() {
	$VALGRIND $RP_BIN \
		--mode standalone \
		--tal "$SANDBOX/$TEST.tal" \
		--local-repository "$SANDBOX/workdir" \
		--report "$SANDBOX/report.txt" \
		--output.roa "$SANDBOX/vrps.csv" \
		--rsync.program "$RSYNC" \
		"$@" \
		> "$SANDBOX/$RP.log" 2>&1
}

# Echoes the location where rp_run() expects to find the TAL file.
# (Barry will drop it there.)
rp_tal_path() {
	echo "$SANDBOX/$TEST.tal"
}

# Echoes the location where rp_run() dropped the VRP file.
rp_vrp_path() {
	echo "$SANDBOX/vrps.csv"
}

# Echoes the location where rp_run() dropped the file listing the validation
# errors.
rp_report_path() {
	echo "$SANDBOX/report.txt"
}
