#!/bin/sh

export RP_BIN_DEFAULT="rpki-prover"
export RP_EV="RPKI_PROVER"
export MEMCHECK_DEFAULT=0

rp_test() {
	$RP_BIN --version > /dev/null
}

rp_run() {
	$VALGRIND $RP_BIN \
		--once \
		--vrp-output "$WORKSPACE/vrps.txt" \
		--no-rir-tals --extra-tals-directory "$WORKSPACE/tal" \
		--rpki-root-directory "$WORKSPACE/workdir" \
		--rsync-client-path "$RSYNC" \
		--log-level debug \
		> "$WORKSPACE/$RP.log" 2>&1
}

rp_tal() {
	echo "$WORKSPACE/tal/$TEST.tal"
}

rp_count_vrps() {
	tail -n +2 $WORKSPACE/vrps.txt | sort | uniq | wc -l
}
