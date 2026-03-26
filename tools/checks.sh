#!/bin/sh

ck_inc() {
	echo -n "1" >> "sandbox/checks/total.txt"
}

fail() {
	echo "$TESTID error: $@" 1>&2
	stop_rp
	stop_router
	exit 1
}

warn() {
	echo "$TESTID warning: $@" 1>&2
	echo -n "1" >> "sandbox/checks/warns.txt"
}

# Use this result when the test does not apply to the RP.
# It's neither a success nor a failure.
skip() {
	echo "$TESTID skipped: $@"
	stop_rp
	stop_router
	exit 3
}

# $1: Basename of the rd (default: "rd")
# $2, $3, $4...: Additional arguments for Barry
run_barry() {
	if [ -z "$1" ]; then
		RD="rd"
	else
		RD="$1"
		shift
	fi

	$BARRY	--rsync-uri "rsync://localhost:8873/rpki/$TEST" \
		--rsync-path "sandbox/rsyncd/content/$TEST" \
		--rrdp-uri "https://localhost:8443/$TEST" \
		--rrdp-path "sandbox/apache2/content/$TEST" \
		--keys "custom/keys" \
		-vv --print-objects "csv" \
		--tal-path "$(rp_tal_path)" \
		"$@" \
		"$SRCDIR/$RD" \
		> "$SANDBOX/barry.txt" 2>&1 \
		|| fail "Barry returned $?; see $SANDBOX/barry.txt"
}

# Runs the RP in single-cycle mode.
# 
# $@: Additional arguments for RP
run_rp() {
	ck_inc # Counts because we check result, Valgrind and timeout
	rp_run "$@"
	export RP_PID="" # Not running
}

# Alternative to run_rp().
# Starts the RP in perpetual mode, leaves it running in the background.
# Enables RTR checks during check_vrps() and check_aspas(), and maybe more in
# the future.
# The test MUST eventually call stop_rp().
# 
# $@: Additional arguments for RP
start_rp() {
	ck_inc

	rp_start "$@"
	export RP_PID="$!"

	# 3s timeout
	for i in $(seq 15); do
		sleep 0.2

		if ! kill -0 "$RP_PID" 2> /dev/null; then
			fail "$RP died. (See $SANDBOX/$RP.log)"
		fi
		if grep -q "$(rp_ready_string)" "$SANDBOX/$RP.log"; then
			return 0
		fi
	done

	stop_rp
	fail "Timeout. $RP did not finish the validation cycle."
}

stop_rp() {
	if [ ! -z "$RP_PID" ]; then
		kill "$RP_PID"
		export RP_PID=""
	fi
}

# Checks the RP generated the $@ VRPs.
# Checks file output VRPs. If the RP is running in perpetual mode,
# also checks the RTR VRPs.
# 
# $@: Sequence of VRPs in "PREFIX-MAXLEN => AS" format.
#     It must be sorted in accordance to `sort`'s default rules.
check_vrps() {
	VRP_DIR="$SANDBOX/vrp"
	EXPECTED="$VRP_DIR/expected.txt"
	ACTUAL_FILE="$VRP_DIR/actual-file.txt"
	ACTUAL_RTR="$VRP_DIR/actual-rtr.txt"
	mkdir -p "$VRP_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	ck_inc
	# Lucky: All supported RPs print the same first 3 columns,
	# so there's no need for a callback.
	tail -n +2 "$(rp_vrp_path)" |
		awk -F, '{ printf "%s-%s => %s\n", $2, $3, $1 }' - |
		sort > "$ACTUAL_FILE"
	diff -B "$EXPECTED" "$ACTUAL_FILE" > "$ACTUAL_FILE.diff" ||
		fail "Unexpected file VRPs; see $VRP_DIR"

	if [ ! -z "$TEST_PID" ]; then
		ck_inc
		$BARRY-rtr -f rapport reset 127.0.0.1 8323 \
			| grep "^VRP" | cut -f2- | sort \
			> "$ACTUAL_RTR"
		diff -B "$EXPECTED" "$ACTUAL_RTR" > "$ACTUAL_RTR.diff" ||
			fail "Unexpected RTR VRPs; see $VRP_DIR"
	fi
}

# Each argument is 1 ASPA.
# Format: "$customerASID:[$providerASIDs]"
# $providerASIDs is a comma-separated list of ASs.
# Example: "10000:[100,200,300]"
# 
# Checks file output ASPAs. If the RP is running in perpetual mode,
# also checks the RTR ASPAs.
check_aspas() {
	ASPA_DIR="$SANDBOX/aspa"
	EXPECTED="$ASPA_DIR/expected.txt"
	ACTUAL_FILE="$ASPA_DIR/actual-file.txt"
	ACTUAL_RTR="$ASPA_DIR/actual-rtr.txt"
	mkdir -p "$ASPA_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	ck_inc
	rp_print_aspas "$ACTUAL_FILE"
	diff -B "$EXPECTED" "$ACTUAL_FILE" > "$ACTUAL_FILE.diff" \
		|| fail "Unexpected file ASPAs; see $ASPA_DIR"

	if [ ! -z "$RP_PID" ]; then
		ck_inc
		$BARRY-rtr -f rapport reset 127.0.0.1 8323 \
			| grep "^ASPA" | cut -f2- | sort \
			> "$ACTUAL_RTR"
		diff -Bb "$EXPECTED" "$ACTUAL_RTR" > "$ACTUAL_RTR.diff" \
			|| fail "Unexpected RTR ASPAs; see $ASPA_DIR"
	fi
}

start_router() {
	test -z "$BARRY_RTR_PID" || fail "The router is already running."

	$BARRY-rtr --input "$SANDBOX/barry-rtr.sk" interactive 127.0.0.1 8323 \
		> "$SANDBOX/barry-rtr.stdout" &
	export BARRY_RTR_PID="$!"
}

send_router_pdu() {
	test ! -z "$BARRY_RTR_PID" || fail "The router is not running."

	echo "$@" | $BARRY-ncu "$SANDBOX/barry-rtr.sk"
}

# Wait at most 3 seconds for $1 PDUs to arrive
wait_pdus() {
	test $(wc -l < "$SANDBOX/barry-rtr.stdout") -ge "$1" && return 0

	for i in 1 2 3; do
		sleep 1
		test $(wc -l < "$SANDBOX/barry-rtr.stdout") -ge "$1" && return 0
	done

	fail "Timeout. $RP didn't reply $1 PDUs; see $SANDBOX/barry-rtr.stdout"
}

# $1: Expect notify? (0 or 1)
# $2-: Expected resource PDUs
check_cache_response() {
	test ! -z "$BARRY_RTR_PID" || fail "The router is not running."

	PDU_DIR="$SANDBOX/pdu"
	EXPECTED="$PDU_DIR/expected.txt"
	ACTUAL="$PDU_DIR/actual.txt"
	DIFF="$PDU_DIR/diff.txt"
	mkdir -p "$PDU_DIR"
	rm -f "$PDU_DIR"/*

	NOTIF="$1"
	if [ "$NOTIF" -eq 0 ]; then
		STATE="2"
	else
		STATE="1"
	fi
	shift

	NEXPECTED="$#"
	wait_pdus $((NOTIF+NEXPECTED+2))
	unset NOTIF
	unset NEXPECTED

	while read LINE; do
		case "$STATE" in
		"1")
			REGEX="serial-notify  version 2 session [0-9]+ length 12 serial [0-9]+"
			echo "$LINE" | grep -qE "$REGEX" ||
				fail "Expected Serial Notify PDU, got '$LINE'."
			STATE="2"
			;;
		"2")
			REGEX="cache-response version 2 session [0-9]+ length 8"
			echo "$LINE" | grep -qE "$REGEX" - ||
				fail "Expected Cache Response PDU, got '$LINE'."
			STATE="3"
			;;
		"3")
			case "$LINE" in
			ipv4-prefix*|ipv6-prefix*|aspa-pdu*)
				echo "$LINE" >> "$ACTUAL.tmp"
				;;
			end-of-data*)
				echo "$LINE" |
					grep -qE "end-of-data    version 2 session [0-9]+ length 24 serial [0-9]+ refresh [0-9]+ retry [0-9]+ expire [0-9]+" - ||
					fail "End of Data PDU does not match the End of Data regex."
				STATE="4"
				;;
			*)
				fail "Unexpected PDU: $LINE"
			esac
			;;
		"4")
			fail "PDU found after End Of Data: $LINE"
			;;
		*)
			fail "Invalid state: $STATE"
			;;
		esac
	done < "$SANDBOX/barry-rtr.stdout"

	truncate -s 0 "$SANDBOX/barry-rtr.stdout"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	sort "$ACTUAL.tmp" > "$ACTUAL"
	rm "$ACTUAL.tmp"

	ck_inc
	diff "$EXPECTED" "$ACTUAL" > "$DIFF" ||
		fail "Unexpected RTR PDUs; see $PDU_DIR"
}

# $@: PDU regexs
check_pdus() {
	test ! -z "$BARRY_RTR_PID" || fail "The router is not running."

	PDU_DIR="$SANDBOX/pdu"
	EXPECTED="$PDU_DIR/regex.txt"
	ACTUAL="$PDU_DIR/actual.txt"
	mkdir -p "$PDU_DIR"
	rm -f "$PDU_DIR"/*

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	wait_pdus "$#"
	cp "$SANDBOX/barry-rtr.stdout" "$ACTUAL"
	truncate -s 0 "$SANDBOX/barry-rtr.stdout"
	
	ck_inc
	while read A; do
		test "$#" -ne 0 ||
			fail "Unexpected RTR PDUs; see $PDU_DIR"
		echo "$A" | grep -Eqx "$1" - ||
			fail "Unexpected RTR PDUs; see $PDU_DIR"
		shift
	done < "$ACTUAL"

	test "$#" -eq 0 || fail "Unexpected RTR PDUs; see $PDU_DIR"
}

# $1: RP
# $2: Expected version
# $3: Expected error code
# $4: Expected Encapsulated PDU
# $5: Expected error message for $1
#
# Arguments $2-$5 are regular expressions.
check_error_report_pdu() {
	test "$RP" = "$1" || return 0
	check_pdus "error-report   version $2 error-code $3 length [0-9]+ encapsulated-pdu-length [0-9]+ encapsulated-pdu \[ $4 \] error-text-length ${#5} error-text $5"
}

revalidate_rp() {
	test ! -z "$RP_PID" || fail "The RP is not running."

	truncate -s 0 "$SANDBOX/$RP.log"
	# TODO Fort hardcode
	kill -USR1 "$RP_PID"

	# 3s timeout
	for i in $(seq 15); do
		sleep 0.2

		if ! kill -0 "$RP_PID" 2> /dev/null; then
			fail "$RP died. (See $SANDBOX/$RP.log)"
		fi
		# TODO Fort hardcode
		if grep -q "Main loop: Sleeping." "$SANDBOX/$RP.log"; then
			return 0
		fi
	done

	stop_rp
	fail "Timeout. $RP did not finish the validation cycle."
}

stop_router() {
	if [ ! -z "$BARRY_RTR_PID" ]; then
		kill "$BARRY_RTR_PID"
		export BARRY_RTR_PID=""
	fi
}

# Checks file $1 contains a line that matches the $3 regex string.
# $1: file to grep in
# $2: grep flags
# $3: regex to search
check_output() {
	ck_inc
	grep -q $2 -- "$3" "$1" || fail "$1 does not contain '$3'"
}

# Checks the RP's report file contains the error message $3.
# However, it only performs the check if the RP is $1.
# $1: RP
# $2: grep flags
# $3: regex to search
check_report() {
	test "$RP" = "$1" || return 0
	check_output $(rp_report_path) "$2" "$3"
}

# Checks the RP's logfile contains the error message $3.
# However, it only performs the check if the RP is $1.
# $1: RP
# $2: grep flags
# $3: regex to search
check_logfile() {
	test "$RP" = "$1" || return 0
	check_output "$SANDBOX/$RP.log" "$2" "$3"
}

# Checks the Apache server received the $@ sequence of requests (and nothing
# else).
# $@: Sequence of HTTP requests in "PATH HTTP_RESULT_CODE" format.
check_http_requests() {
	APACHE_DIR="$SANDBOX/apache2"
	EXPECTED="$APACHE_DIR/expected.log"
	ACTUAL="$APACHE_DIR/actual.log"
	DIFF="$APACHE_DIR/diff.txt"
	mkdir -p "$APACHE_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	cp "$APACHE_REQLOG" "$ACTUAL"
	:> "$APACHE_REQLOG"

	ck_inc
	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| warn "Unexpected Apache request sequence; see $APACHE_DIR"
}

# Checks the rsync server received the $@ sequence of requests (and nothing
# else).
# $@: Sequence of rsync requests in "PATH" format.
check_rsync_requests() {
	RSYNC_DIR="$SANDBOX/rsync"
	EXPECTED="$RSYNC_DIR/expected.log"
	ACTUAL="$RSYNC_DIR/actual.log"
	DIFF="$RSYNC_DIR/diff.txt"
	mkdir -p "$RSYNC_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "rsync on $i from localhost" >> "$EXPECTED"
	done

	grep -o "rsync on .* from localhost" "$RSYNC_REQLOG" > "$ACTUAL"
	:> "$RSYNC_REQLOG"

	ck_inc
	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| warn "Unexpected rsync request sequence; see $RSYNC_DIR"
}

# $@: Same as run_barry
create_delta() {
	sleep 1 # Wait out HTTP IMS. TODO May be unnecessary

	APACHEDIR="sandbox/apache2/content/$TEST"
	TMPDIR="sandbox/tmp/$TEST"

	rm -r "sandbox/rsyncd/content/$TEST"

	mkdir -p "$TMPDIR"
	rm -rf "$TMPDIR/"*
	mv "$APACHEDIR" "$TMPDIR/old"

	run_barry "$@"
	mv "$APACHEDIR" "$TMPDIR/new"

	mkdir "$APACHEDIR"
	$BARRY-delta \
		--old.notification	"$TMPDIR/old/notification.xml" \
		--old.snapshot		"$TMPDIR/old/snapshot.xml" \
		--new.notification	"$TMPDIR/new/notification.xml" \
		--new.snapshot		"$TMPDIR/new/snapshot.xml" \
		--output.notification	"$APACHEDIR/notification.xml" \
		--output.delta.path	"$APACHEDIR/delta-$1.xml" \
		--output.delta.uri	"https://localhost:8443/$TEST/delta-$1.xml" \
		> "$SANDBOX/barry-delta.txt" 2>&1 \
		|| fail "barry-delta returned $?; see $SANDBOX/barry-delta.txt"

	mv "$TMPDIR/new/snapshot.xml" "$APACHEDIR"
	diff "$TMPDIR/old/ta.cer" "$TMPDIR/new/ta.cer" > /dev/null \
		&& mv "$TMPDIR/new/ta.cer" "$APACHEDIR" \
		|| mv "$TMPDIR/old/ta.cer" "$APACHEDIR"
	rm -r "$TMPDIR"
}
