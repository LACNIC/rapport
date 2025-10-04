#!/bin/sh

export RP_BIN_DEFAULT="rpki-client"
export RP_EV="RPKI_CLIENT"
export MEMCHECK_DEFAULT=1

rp_test() {
	$RP_BIN -V > /dev/null
}

rp_run() {
	mkdir -p "$WORKSPACE/outputdir"
	$VALGRIND $RP_BIN \
		-t "$TAL" \
		-d "$WORKSPACE/workdir" \
		"$WORKSPACE/outputdir" \
		> "$WORKSPACE/$RP.log" 2>&1
}

rp_tal() {
	echo "$WORKSPACE/$TEST.tal"
}

rp_count_vrps() {
	ROWS=$(wc -l < "$WORKSPACE/outputdir/csv")
	echo "$((ROWS-1))"
}
