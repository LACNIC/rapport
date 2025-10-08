#!/bin/sh

export RP_BIN_DEFAULT="routinator"
export RP_EV="ROUTINATOR"
export MEMCHECK_DEFAULT=0

rp_test() {
	$RP_BIN -V > /dev/null
}

rp_run() {
	$VALGRIND $RP_BIN \
		-r "$WORKSPACE/workdir" \
		--no-rir-tals --extra-tals-dir "$WORKSPACE/tal" \
		--log-repository-issues --logfile "$WORKSPACE/$RP.log" \
		vrps \
		> "$WORKSPACE/vrps.csv" 2> "$WORKSPACE/stderr.txt"
}

rp_tal_path() {
	echo "$WORKSPACE/tal/$TEST.tal"
}

rp_vrp_path() {
	echo "$WORKSPACE/vrps.csv"
}
