#!/bin/sh

# This one is temporal; I'm not planning on supporting it for long.

export RP_BIN_DEFAULT="fort"
export RP_EV="FORT"
export RP_TEST="-V"
export MEMCHECK_DEFAULT=1

rp_run() {
	$VALGRIND $RP_BIN \
		--mode standalone \
		--tal "$SANDBOX/$TEST.tal" \
		--local-repository "$SANDBOX/workdir" \
		--output.roa "$SANDBOX/vrps.csv" \
		--output.aspa "$SANDBOX/aspa.json" \
		--log.level=debug \
		--log.color \
		--validation-log.enabled \
		--validation-log.level=debug \
		--validation-log.color \
		"$@" \
		> "$SANDBOX/$RP.log" 2>&1
}

rp_tal_path() {
	echo "$SANDBOX/$TEST.tal"
}

rp_vrp_path() {
	echo "$SANDBOX/vrps.csv"
}

rp_print_aspas() {
	jq -r '.aspa | keys[] as $k | [$k, (.[$k] | tostring)] | join(":")' \
		"$SANDBOX/aspa.json" > "$1"
}

rp_report_path() {
	echo "$SANDBOX/fort1.log"
}
