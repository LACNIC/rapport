#!/bin/sh

# This one is temporal; I'm not planning on supporting it for long.

export RP_BIN_DEFAULT="fort"
export RP_EV="FORT"
export RP_TEST="-V"
export MEMCHECK_DEFAULT=1

rp_run() {
	timeout 3s $VALGRIND $RP_BIN \
		--mode "standalone" \
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
		> "$SANDBOX/$RP.log" 2>&1 \
		|| fail "$RP_BIN returned $?; see $SANDBOX/$RP.log"
}

rp_start() {
	# Logic to change the IP to 10.0.0.1 only in case of testing with a Cisco router.
	if [ "$1" = "for_cisco_test" ]; then
        SERVER_IP="10.0.0.1"
        # We only shift if it's "for_cisco_test" so that it doesn't go to the binary
        shift
    else
        SERVER_IP="127.0.0.1"
        # We do NOT shift: "$1" stays as "$@" for binary
    fi
	# TODO Valgrind?
	# Since we'll have to SIGTERM the RP later,
	# I'm not sure if Valgrind makes sense here.
	$RP_BIN \
		--mode "server" \
		--server.address "$SERVER_IP" \
		--server.port "8323" \
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
		> "$SANDBOX/$RP.log" 2>&1 &
}

rp_ready_string() {
	echo "First validation cycle successfully ended"
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
