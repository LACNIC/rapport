#!/bin/sh

ck_inc() {
	echo -n "1" >> "sandbox/checks/total.txt"
}

fail() {
	echo "$TESTID error: $@" 1>&2
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

# $@: Additional arguments
run_rp() {
	ck_inc # Counts because we check result value and Valgrind
	rp_run "$@" || fail "$RP returned $? (See $SANDBOX/$RP.log)"
}

# Checks the RP generated $1 VRPs.
# This test is redundant if you also do check_vrp_output().
# $1: Expected VRP count
check_vrp_count() {
	ck_inc
	ROWS=$(wc -l < "$(rp_vrp_path)")
	ACTUAL=$((ROWS-1))
	test "$1" -eq "$ACTUAL" \
		|| fail "Expected $1 VRP(s), $RP produced $ACTUAL"
}

# Checks the RP generated the $@ VRPs.
# $@: Sequence of VRPs in "PREFIX-MAXLEN => AS" format.
#     It must be sorted in accordance to `sort`'s default rules.
check_vrp_output() {
	VRP_DIR="$SANDBOX/vrp"
	EXPECTED="$VRP_DIR/expected.txt"
	ACTUAL="$VRP_DIR/actual.txt"
	DIFF="$VRP_DIR/diff.txt"
	mkdir -p "$VRP_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	# Lucky: All supported RPs print the same first 3 columns,
	# so there's no need for a callback.
	tail -n +2 "$(rp_vrp_path)" |
		awk -F, '{ printf "%s-%s => %s\n", $2, $3, $1 }' - |
		sort > "$ACTUAL"

	ck_inc
	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected VRPs; see $VRP_DIR"
}

# Each argument is 1 ASPA.
# Format: "$customerASID:[$providerASIDs]"
# $providerASIDs is a comma-separated list of ASs.
# Example: "10000:[100,200,300]"
check_aspa_output() {
	ASPA_DIR="$SANDBOX/aspa"
	EXPECTED="$ASPA_DIR/expected.txt"
	ACTUAL="$ASPA_DIR/actual.txt"
	DIFF="$ASPA_DIR/diff.txt"
	mkdir -p "$ASPA_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	rp_print_aspas "$ACTUAL"

	ck_inc
	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected ASPAs; see $ASPA_DIR"
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
		--old.snapshot		"$TMPDIR/old/notification.xml.snapshot" \
		--new.notification	"$TMPDIR/new/notification.xml" \
		--new.snapshot		"$TMPDIR/new/notification.xml.snapshot" \
		--output.notification	"$APACHEDIR/notification.xml" \
		--output.delta.path	"$APACHEDIR/delta-$1.xml" \
		--output.delta.uri	"https://localhost:8443/$TEST/delta-$1.xml" \
		> "$SANDBOX/barry-delta.txt" 2>&1 \
		|| fail "barry-delta returned $?; see $SANDBOX/barry-delta.txt"

	mv "$TMPDIR/new/notification.xml.snapshot" "$APACHEDIR"
	diff "$TMPDIR/old/ta.cer" "$TMPDIR/new/ta.cer" > /dev/null \
		&& mv "$TMPDIR/new/ta.cer" "$APACHEDIR" \
		|| mv "$TMPDIR/old/ta.cer" "$APACHEDIR"
	rm -r "$TMPDIR"
}
