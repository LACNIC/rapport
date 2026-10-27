#!/bin/sh

COLOR_YLW='\033[33m'
COLOR_RED='\033[31m'
COLOR_RST='\033[0m'

ck_inc() {
	echo -n "1" >> "sandbox/counters/total.txt"
}

# $1: Text color
# $2: Error message. Must not include its ending period.
# $3..: Files and directories the user will be invited to read.
print_errmsg() {
	COLOR="$1"
	echo "$COLOR  $2. Try$COLOR_RST" 1>&2
	shift 2

	while [ ! -z "$1" ]; do
		find "$1" -type f | while read f; do
			echo "$COLOR  - $f$COLOR_RST" 1>&2
		done
		shift
	done
	echo "$COLOR  - $SRCDIR/run.sh$COLOR_RST" 1>&2
}


__fail() {
	print_errmsg "$COLOR_RED" "$@"
	exit 1
}

fail() {
	stop_rp
	stop_router
	__fail "$@"
}

warn() {
	print_errmsg "$COLOR_YLW" "$@"
	echo -n "1" >> "sandbox/counters/warns.txt"
}

# Use this result when the test does not apply to the RP.
# It's neither a success nor a failure.
skip() {
	echo "  Skipped."
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

	$BARRY	--rsync-uri  "rsync://localhost:8873/rpki/$TEST" \
		--rsync-path "sandbox/rsyncd/content/$TEST" \
		--rrdp-uri   "https://localhost:8443/$TEST" \
		--rrdp-path  "sandbox/apache2/content/$TEST" \
		--serial "$STEP" \
		--previous-path "sandbox/$SRCDIR/step$STEP_PREV/rsyncd/content/$TEST" \
		--keys "custom/keys" \
		-vv --print-objects "csv" \
		--tal-path "$(rp_tal_path)" \
		"$@" \
		"$SRCDIR/$RD" \
		>> "$SANDBOX/barry.txt" 2>&1 \
		|| fail "Barry returned $?" "$SANDBOX/barry.txt"
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

	wait_rp_output "$(rp_ready_string)"
}

# Check the program $1 is still running.
# Its PID must be $2, and its logfile must be $3.
check_pid_running() {
	kill -0 "$2" 2> /dev/null || fail "$1 died" "$3"
}

# Waits until the file $3 contains the string $4, with 30s timeout.
# The program of $2's writer is assumed to be $1, with PID $2.
wait_output() {
	for i in $(seq 150); do
		sleep 0.2
		check_pid_running "$1" "$2" "$3"
		grep -Fq "$4" "$3" && return 0
	done

	stop_rp
	fail "Timeout. $3 does not contain '$4'"
}

# Wait until the RP logs the string "$1".
wait_rp_output() {
	wait_output "$RP_BIN" "$RP_PID" "$SANDBOX/$RP.log" "$1"
}

# Wait until barry-rtr prints the string "$1".
wait_router_output() {
	wait_output "$BARRY-rtr" "$BARRY_RTR_PID" \
		"$SANDBOX/barry-rtr.stdout" "$1"
}

stop_rp() {
	if [ ! -z "$RP_PID" ]; then
		kill "$RP_PID"
		wait "$RP_PID" || __fail "$RP_BIN returned $?" "$SANDBOX/$RP.log"
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
		fail "Unexpected file VRPs" "$VRP_DIR" "$SANDBOX/$RP.log"

	if [ ! -z "$TEST_PID" ]; then
		ck_inc
		$BARRY-rtr -f rapport reset 127.0.0.1 8323 \
			| grep "^VRP" | cut -f2- | sort \
			> "$ACTUAL_RTR"
		diff -B "$EXPECTED" "$ACTUAL_RTR" > "$ACTUAL_RTR.diff" ||
			fail "Unexpected RTR VRPs" "$VRP_DIR" "$SANDBOX/$RP.log"
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
		|| fail "Unexpected file ASPAs" "$ASPA_DIR" "$SANDBOX/$RP.log"

	if [ ! -z "$RP_PID" ]; then
		ck_inc
		$BARRY-rtr -f rapport reset 127.0.0.1 8323 \
			| grep "^ASPA" | cut -f2- | sort \
			> "$ACTUAL_RTR"
		diff -Bb "$EXPECTED" "$ACTUAL_RTR" > "$ACTUAL_RTR.diff" \
			|| fail "Unexpected RTR ASPAs" "$ASPA_DIR" "$SANDBOX/$RP.log"
	fi
}

start_router() {
	test -z "$BARRY_RTR_PID" || fail "The router is already running"

	$BARRY-rtr --input "$BARRY_RTR_SK" interactive 127.0.0.1 8323 \
		>> "$SANDBOX/barry-rtr.stdout" &
	export BARRY_RTR_PID="$!"
	wait_router_output "Ready."
	truncate -s 0 "$SANDBOX/barry-rtr.stdout"
}

send_router_pdu() {
	test ! -z "$BARRY_RTR_PID" || fail "The router is not running"

	echo "$@" | $BARRY-ncu "$BARRY_RTR_SK"
}

# Wait at most 15 seconds for $1 PDUs to arrive
wait_pdus() {
	for i in $(seq 75); do
		test $(wc -l < "$SANDBOX/barry-rtr.stdout") -ge "$1" && return 0
		check_pid_running "$RP_BIN" "$RP_PID" "$SANDBOX/$RP.log"
		sleep 0.2
	done

	fail "Timeout; $RP didn't reply $1 PDUs" "$SANDBOX/$RP.log" "$SANDBOX/barry-rtr.stdout"
}

# $1: Expect notify? (0 or 1)
# $2: Expected serial
# $3-: Expected resource PDUs
check_cache_response() {
	NOTIF="$1"
	SERIAL="$2"
	shift 2

	if [ "$NOTIF" -eq 1 ]; then
		check_pdus \
			"serial-notify  version 2 session [0-9]+ length 12 serial [0-9]+" \
			"cache-response version 2 session [0-9]+ length 8" \
			"$@" \
			"end-of-data    version 2 session [0-9]+ length 24 serial $SERIAL refresh [0-9]+ retry [0-9]+ expire [0-9]+"
	else
		check_pdus \
			"cache-response version 2 session [0-9]+ length 8" \
			"$@" \
			"end-of-data    version 2 session [0-9]+ length 24 serial $SERIAL refresh [0-9]+ retry [0-9]+ expire [0-9]+"
	fi
}

check_cache_response_v0() {
	NOTIF="$1"
	SERIAL="$2"
	shift 2

	if [ "$NOTIF" -eq 1 ]; then
		check_pdus \
			"serial-notify  version 0 session [0-9]+ length 12 serial [0-9]+" \
			"cache-response version 0 session [0-9]+ length 8" \
			"$@" \
			"end-of-data    version 0 session [0-9]+ length 12 serial $SERIAL"
	else
		check_pdus \
			"cache-response version 0 session [0-9]+ length 8" \
			"$@" \
			"end-of-data    version 0 session [0-9]+ length 12 serial $SERIAL"
	fi
}

# Please do not use this function is you're expecting a normal
# cache-response to end-of-data stream. Prefer check_cache_response*()
# if that is the case.
# 
# $@: PDU regexs
check_pdus() {
	test ! -z "$BARRY_RTR_PID" || fail "The router is not running"

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
			fail "Unexpected RTR PDUs" "$PDU_DIR" "$SANDBOX/$RP.log"
		echo "$A" | grep -Eqx "$1" - ||
			fail "Unexpected RTR PDUs" "$PDU_DIR" "$SANDBOX/$RP.log"
		shift
	done < "$ACTUAL"

	test "$#" -eq 0 || fail "Unexpected RTR PDUs" "$PDU_DIR" "$SANDBOX/$RP.log"
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
	test ! -z "$RP_PID" || fail "The RP is not running"

	truncate -s 0 "$SANDBOX/$RP.log"
	# TODO Fort hardcode
	kill -USR1 "$RP_PID"

	# TODO Fort hardcode
	wait_rp_output "Main loop: Sleeping."
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

	# For check_stray_log_errs()
	case "$3" in
	"ERR: "*|"TRE: "*)
		mkdir -p "$SANDBOX/log-checks"
		echo "$COLOR_RED$3$COLOR_RST" >> "$SANDBOX/log-checks/expected.log"
		;;
	"WRN: "*|"TRW: "*)
		mkdir -p "$SANDBOX/log-checks"
		echo "$COLOR_YLW$3$COLOR_RST" >> "$SANDBOX/log-checks/expected.log"
		;;
	esac
}

check_stray_log_errs() {
	if [ -f "$SANDBOX/.disable-log-checks" ]; then
		rm "$SANDBOX/.disable-log-checks"
		return
	fi

	LOGDIR="$SANDBOX/log-checks"
	EXPECTED="$LOGDIR/expected.log"
	ACTUAL="$LOGDIR/actual.log"
	DIFF="$LOGDIR/diff.txt"

	mkdir -p "$LOGDIR"
	test -f "$EXPECTED" || :> "$EXPECTED"
	grep -E "(WRN|ERR|TRW|TRE): " "$SANDBOX/$RP.log" > "$ACTUAL"

	ck_inc
	diff "$EXPECTED" "$ACTUAL" > "$DIFF" ||
		fail "Unexpected warnings and/or errors" "$LOGDIR" "$SANDBOX/$RP.log"
}

# Checks the Apache server received the $@ sequence of requests (and nothing
# else).
# $@: Sequence of HTTP requests in "PATH HTTP_RESULT_CODE" format.
check_http_requests() {
	APACHE_DIR="$SANDBOX/apache2-checks"
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
	RSYNC_DIR="$SANDBOX/rsync-checks"
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

# TODO Redesign this; it's too complicated.
# Most of the boilerplate should be done by Barry.
#
# $@: Same as run_barry
create_delta() {
	# Preparations
	APACHEDIR="sandbox/apache2/content/$TEST"
	TMPDIR="sandbox/tmp/$TEST"

	# Barry already deltas rsync properly. We already backed up the rsyncd
	# workspace during new_step(), so just clear it.
	clear_rsync_modules

	mkdir -p "$TMPDIR"
	rm -rf "$TMPDIR/"*

	mv "$APACHEDIR" "$TMPDIR/main"

	run_barry "$@"
	mv "$APACHEDIR" "$TMPDIR/mid"

	mkdir "$TMPDIR/new"

	# Root XMLs
	$BARRY-delta \
		--old.notification    "$TMPDIR/main/notification.xml" \
		--old.snapshot        "$TMPDIR/main/snapshot.xml" \
		--new.notification    "$TMPDIR/mid/notification.xml" \
		--new.snapshot        "$TMPDIR/mid/snapshot.xml" \
		--output.notification "$TMPDIR/new/notification.xml" \
		--output.delta.path   "$TMPDIR/new/delta-$1.xml" \
		--output.delta.uri    "https://localhost:8443/$TEST/delta-$1.xml" \
		> "$SANDBOX/barry-delta.txt" 2>&1 \
		|| fail "barry-delta returned $?" "$SANDBOX/barry-delta.txt"
	mv "$TMPDIR/new/notification.xml" "$TMPDIR/main"
	mv "$TMPDIR/mid/snapshot.xml" "$TMPDIR/main"
	mv "$TMPDIR/new/delta-$1.xml" "$TMPDIR/main"

	# Additional XMLs requested by caller
	for i in $RRDP_SUBDIRS; do
		$BARRY-delta \
			--old.notification    "$TMPDIR/main/$i/notification.xml" \
			--old.snapshot        "$TMPDIR/main/$i/snapshot.xml" \
			--new.notification    "$TMPDIR/mid/$i/notification.xml" \
			--new.snapshot        "$TMPDIR/mid/$i/snapshot.xml" \
			--output.notification "$TMPDIR/new/$i/notification.xml" \
			--output.delta.path   "$TMPDIR/new/$i/delta-$1.xml" \
			--output.delta.uri    "https://localhost:8443/$TEST/$i/delta-$1.xml" \
			> "$SANDBOX/barry-delta-$i.txt" 2>&1 \
			|| fail "barry-delta returned $?" "$SANDBOX/barry-delta-$i.txt"
		mv "$TMPDIR/new/$i/notification.xml" "$TMPDIR/main/$i"
		mv "$TMPDIR/mid/$i/snapshot.xml" "$TMPDIR/main/$i"
		mv "$TMPDIR/new/$i/delta-$1.xml" "$TMPDIR/main/$i"
	done

	# HTTP TA
	diff "$TMPDIR/main/ta.cer" "$TMPDIR/mid/ta.cer" > /dev/null \
		&& mv "$TMPDIR/mid/ta.cer" "$TMPDIR/main/ta.cer"

	# Cleanup
	mv "$TMPDIR/main" "$APACHEDIR"
	rm -r "$TMPDIR"
}

new_step() {
	check_stray_log_errs

	# The latest sandbox has to be named "latest" because it needs a
	# constant name.
	# This is because the path of the RP log, RP cache and RTR socket file
	# need to be preserved between steps, in case the RP is in ongoing mode.

	BKP_SANDBOX="sandbox/$SRCDIR/step$STEP"
	mkdir "$BKP_SANDBOX"

	cp -rp "sandbox/apache2" "$BKP_SANDBOX/apache2"
	cp -rp "sandbox/rsyncd" "$BKP_SANDBOX/rsyncd"
	cp -rp "$SANDBOX/workdir" "$BKP_SANDBOX/workdir"
	if [ -f "$SANDBOX/$RP.log" ]; then
		cp -rp "$SANDBOX/$RP.log" "$BKP_SANDBOX/$RP.log"
		truncate -s 0 "$SANDBOX/$RP.log"
	fi
	if [ -f "$SANDBOX/barry-rtr.stdout" ]; then
		cp -rp "$SANDBOX/barry-rtr.stdout" "$BKP_SANDBOX/barry-rtr.stdout"
		truncate -s 0 "$SANDBOX/barry-rtr.stdout"
	fi

	for i in "$SANDBOX"/*; do
		BN="$(basename "$i")"
		# TODO stdout and stderr also need to be preserved,
		# but this presently only bugs Routinator.
		test "$BN" != "$RP.log" \
			-a "$BN" != "workdir" \
			-a "$BN" != "barry-rtr.stdout" \
			&& mv "$i" "$BKP_SANDBOX/$BN"
	done

	sleep 1 # Wait out HTTP IMS and rsync IMS

	STEP_PREV="$STEP"
	STEP="$((STEP+1))"
	#echo "  Step $STEP"
}

clear_rsync_modules() {
	rm -rf "sandbox/rsyncd/content/"* \
		"sandbox/rsyncd/repo1/"* "sandbox/rsyncd/repo2/"* \
		"sandbox/rsyncd/repo3/"* "sandbox/rsyncd/repo4/"*
}
