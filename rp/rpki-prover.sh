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
		--vrp-output "$SANDBOX/vrps.txt" \
		--no-rir-tals --extra-tals-directory "$SANDBOX/tal" \
		--rpki-root-directory "$SANDBOX/workdir" \
		--rsync-client-path "$RSYNC" \
		--log-level debug \
		> "$SANDBOX/$RP.log" 2>&1
}

rp_tal_path() {
	echo "$SANDBOX/tal/$TEST.tal"
}

rp_vrp_path() {
	echo "$SANDBOX/vrps.txt"
}
