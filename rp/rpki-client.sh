#!/bin/sh

export RP_BIN_DEFAULT="rpki-client"
export RP_EV="RPKI_CLIENT"
export MEMCHECK_DEFAULT=1

rp_test() {
	$RP_BIN -V 2> /dev/null
}

rp_run() {
	mkdir -p "$WORKSPACE/outputdir"
	$VALGRIND $RP_BIN \
		-t "$WORKSPACE/$TEST.tal" \
		-d "$WORKSPACE/workdir" \
		"$WORKSPACE/outputdir" \
		> "$WORKSPACE/$RP.log" 2>&1
}

rp_tal_path() {
	echo "$WORKSPACE/$TEST.tal"
}

rp_vrp_path() {
	echo "$WORKSPACE/outputdir/csv"
}
