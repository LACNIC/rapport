#!/bin/sh

fail() {
	RESULT="$?"
	if [ "$RESULT" -ne 0 ]; then
		echo "$TEST: $1"
		exit "$RESULT"
	fi
}

# $1: Name of the rd
run_barry_default() {
	$BARRY --rsync-path "sandbox/rsyncd/content" \
		--rrdp-path "sandbox/apache2/content/rrdp" \
		--keys "sandbox/keys" \
		--print-objects "csv" \
		--tal-path "$(rp_tal_path)" \
		"$SRCDIR/$1" \
		> "$SANDBOX/barry.txt" 2>&1 \
		|| fail "Barry returned $?"
}

run_rp_default() {
	rp_run || fail "$RP returned $?"
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

	touch "$EXPECTED"
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

	touch "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	cp "$APACHE_REQLOG" "$ACTUAL"

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

	touch "$EXPECTED"
	for i in "$@"; do
		echo "rsync on $i from localhost" >> "$EXPECTED"
	done

	grep -o "rsync on .* from localhost" "$RSYNC_REQLOG" > "$ACTUAL"

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF" \
		|| fail "Unexpected rsync request sequence; see $RSYNC_DIR"
}
