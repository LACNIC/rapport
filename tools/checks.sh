#!/bin/sh

fail() {
	echo "$TEST: $1" 1>&2
	exit 1
}

# Use this result when the test does not apply to the RP.
# It's neither a success nor a failure.
skip() {
	echo "$TEST skipped: $1"
	exit 3
}

# $1: Name of the rd
# $2, $3, $4...: Additional arguments for Barry
run_barry() {
	RD="$1"
	shift
	$BARRY	--rsync-uri "rsync://localhost:8873/rpki/$TEST" \
		--rsync-path "sandbox/rsyncd/content/$TEST" \
		--rrdp-uri "https://localhost:8443/$TEST" \
		--rrdp-path "sandbox/apache2/content/$TEST" \
		--keys "sandbox/keys" \
		-vv --print-objects "csv" \
		--tal-path "$(rp_tal_path)" \
		"$@" \
		"$SRCDIR/$RD" \
		> "$SANDBOX/barry.txt" 2>&1 \
		|| fail "Barry returned $?; see $SANDBOX/barry.txt"
}

# $@: Additional arguments
run_rp() {
	rp_run "$@" || fail "$RP returned $?"
}

# Checks the RP generated $1 VRPs.
# This test is redundant if you also do check_vrp_output().
# $1: Expected VRP count
check_vrp_count() {
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

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected VRPs; see $VRP_DIR"
}

# Checks the RP's logfile contains a line that matches the $3 regex string.
# Needs work, because it currently only supports Fort.
# $1: file to grep in
# $2: grep flags
# $3: regex to search
check_output() {
	if [ "$RP" != "fort2" ]; then
		# Haven't figured out how this is going to work for other RPs
		return
	fi

	grep -q $2 -- "$3" "$SANDBOX/$1" \
		|| fail "$SANDBOX/$1 does not contain '$3'"
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

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected Apache request sequence; see $APACHE_DIR"
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

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected rsync request sequence; see $RSYNC_DIR"
}

# $@: Same as run_barry
create_delta() {
	sleep 1 # Wait out HTTP IMS. TODO May be unnecessary

	APACHEDIR="sandbox/apache2/content/$TEST"
	TMPDIR="sandbox/tmp/$TEST"

	rm -r "sandbox/rsyncd/content/$TEST"

	mkdir -p "$TMPDIR"
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
	mv "$TMPDIR/new/ta.cer" "$APACHEDIR"
	rm -r "$TMPDIR"
}
