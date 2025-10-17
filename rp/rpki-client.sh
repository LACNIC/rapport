#!/bin/sh

export RP_BIN_DEFAULT="rpki-client"
export RP_EV="RPKI_CLIENT"
export RP_TEST="-V"
export MEMCHECK_DEFAULT=1

rp_run() {
	mkdir -p "$SANDBOX/outputdir"
	$VALGRIND $RP_BIN \
		-t "$SANDBOX/$TEST.tal" \
		-d "$SANDBOX/workdir" \
		-e "$RSYNC" \
		"$@" \
		"$SANDBOX/outputdir" \
		> "$SANDBOX/$RP.log" 2>&1
}

rp_tal_path() {
	echo "$SANDBOX/$TEST.tal"
}

rp_vrp_path() {
	echo "$SANDBOX/outputdir/csv"
}

rp_report_path() {
	echo "$SANDBOX/$RP.log"
}
