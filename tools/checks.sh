#!/bin/sh

fail() {
	echo "Test '$TEST' error: $1" 1>&2
	exit 1
}

warn() {
	echo "Test '$TEST' warning: $1" 1>&2
	exit 2
}

# Use this result when the test does not apply to the RP.
# It's neither a success nor a failure.
skip() {
	echo "Test '$TEST' skipped: $1"
	exit 3
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
	tail -n +2 "$SANDBOX/vrps.csv" |
		awk -F, '{ printf "%s-%s => %s\n", $2, $3, $1 }' - |
		sort > "$ACTUAL"

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected VRPs; see $VRP_DIR"
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

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| warn "Unexpected rsync request sequence; see $RSYNC_DIR"
}
