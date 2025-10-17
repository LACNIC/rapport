#!/bin/sh

export RP_BIN_DEFAULT="routinator"
export RP_EV="ROUTINATOR"
export RP_TEST="-V"
export MEMCHECK_DEFAULT=0

rp_run() {
	$VALGRIND $RP_BIN \
		-r "$SANDBOX/workdir" \
		--no-rir-tals --extra-tals-dir "$SANDBOX/tal" \
		--log-repository-issues --logfile "$SANDBOX/$RP.log" \
		--rsync-command "$RSYNC" \
		--allow-dubious-hosts \
		"$@" \
		vrps \
		> "$SANDBOX/vrps.csv" 2> "$SANDBOX/stderr.txt"
}

rp_tal_path() {
	echo "$SANDBOX/tal/$TEST.tal"
}

rp_vrp_path() {
	echo "$SANDBOX/vrps.csv"
}

rp_report_path() {
	echo "$SANDBOX/$RP.log"
}
