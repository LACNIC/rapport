#!/bin/sh

ck_inc() {
	echo -n "1" >> "sandbox/checks/total.txt"
}

fail() {
	echo "$TEST error: $@" 1>&2
	exit 1
}

warn() {
	echo "$TEST warning: $@" 1>&2
	echo -n "1" >> "sandbox/checks/warns.txt"
}

# Use this result when the test does not apply to the RP.
# It's neither a success nor a failure.
skip() {
	echo "$TEST skipped: $@"
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

# Private
check_fort_cache_cages() {
	ck_inc
	LOC="$SANDBOX/workdir/$1"
	ACTUAL=$(ls -Ub1 "$LOC" | grep -c "\\.json$")
	test $2 = "$ACTUAL" || fail "$LOC contains $ACTUAL cages ($2 expected)"
}

# Checks the cache contains only the given cages.
# Fort-only.
#
# $1: Number of rsync cages
# $2: Number of https cages
check_fort_cache() {
	test "$RP" = "fort2" || return 0

	check_fort_cache_cages "rsync" "$1"
	check_fort_cache_cages "https" "$2"
}

# Checks Fort cached the file whose HTTP URL is $1.
# Fort-only.
check_fort_cache_file() {
	ck_inc

	PROTO=$(echo "$1" | cut -c1-5 -)
	for JSON in "$SANDBOX/workdir/$PROTO/"*.json; do
		FILEURI=$(jq -r '.uri' "$JSON")
		test "$1" = "$FILEURI" && return
	done

	fail "$1 was not cached in $SANDBOX/workdir/$PROTO"
}

check_fort_cache_cage_begin() {
	test "$RP" = "fort2" || return 0

	check_fort_cache_file "$1"

	RRDP_DIR="$SANDBOX/rrdp"
	mkdir -p "$RRDP_DIR"

	CAGE_ID="$(basename "$JSON" .json)"
	# Files defined by the JSON
	JSON_FILES="$RRDP_DIR/cg$CAGE_ID-all-json-files.txt"
	# Files referenced by sessions and fallbacks in the JSON
	REFD_FILES="$RRDP_DIR/cg$CAGE_ID-all-refd-files.txt"
	# Actual files in the directory
	DIR_FILES="$RRDP_DIR/cg$CAGE_ID-all-dir-files.txt"

	SORT="sort -k1b,1" # For compatibility with join
	jq -r '.rrdp.files | to_entries[] | [.key, .value.uri] | @tsv' "$JSON" | $SORT -k1b,1 > "$JSON_FILES"
}

# $1: Session ID
# $2: Session serial
# $3...: Files that should've been cached in this session/serial.
check_fort_cache_rrdp_step() {
	test "$RP" = "fort2" || return 0

	SID="$1"
	SERIAL="$2"
	shift 2

	ID="cg$CAGE_ID-ss$SID-se$SERIAL"
	EXPCTD="$RRDP_DIR/$ID-expected.txt"
	ACTUAL="$RRDP_DIR/$ID-actual.txt"
	DIFF="$RRDP_DIR/$ID.diff"

	:> "$EXPCTD"
	for i in "$@"; do
		echo "rsync://localhost:8873/rpki/$TEST/$i" >> "$EXPCTD"
	done

	SS_FILES="$RRDP_DIR/$ID-files.txt"
	jq -r ".rrdp.sessions.\"$SID\".steps.\"$SERIAL\".files | values[]" "$JSON" | $SORT > "$SS_FILES"
	join -o 1.2 "$JSON_FILES" "$SS_FILES" | $SORT > "$ACTUAL"

	ck_inc
	diff -B "$EXPCTD" "$ACTUAL" > "$DIFF" \
		|| warn "Unexpected RRDP session files; see $RRDP_DIR/$ID*"

	cat "$SS_FILES" >> "$REFD_FILES"
}

# $1: Session ID
# $2: Fallback URI
# $3...: Files that should've been cached in this session/fallback.
check_fort_cache_rrdp_fallback() {
	test "$RP" = "fort2" || return 0

	SID="$1"
	FALLBACK="$2"
	shift 2

	ID="cg$CAGE_ID-fb$(basename "$FALLBACK")"
	EXPCTD="$RRDP_DIR/$ID-expected.txt"
	ACTUAL="$RRDP_DIR/$ID-actual.txt"
	DIFF="$RRDP_DIR/$ID.diff"

	:> "$EXPCTD"
	for i in "$@"; do
		echo "rsync://localhost:8873/rpki/$TEST/$i" >> "$EXPCTD"
	done

	FB_FILES="$RRDP_DIR/$ID-files.txt"
	jq -r ".rrdp.sessions.\"$SID\".fallbacks.\"$FALLBACK\".files | values[]" "$JSON" | $SORT > "$FB_FILES"
	join -o 1.2 "$JSON_FILES" "$FB_FILES" | $SORT > "$ACTUAL"

	ck_inc
	diff -B "$EXPCTD" "$ACTUAL" > "$DIFF" \
		|| warn "Unexpected RRDP fallback files; see $RRDP_DIR/$ID*"

	cat "$FB_FILES" >> "$REFD_FILES"
}

check_fort_cache_cage_end() {
	test "$RP" = "fort2" || return 0

	EXPCTD="$JSON_FILES.trimmed"
	ACTUAL="$REFD_FILES.trimmed"
	DIFF="$RRDP_DIR/filerefs.diff"

	cut -f1 "$JSON_FILES" > "$EXPCTD"
	$SORT "$REFD_FILES" | uniq > "$ACTUAL"

	ck_inc
	diff -B "$EXPCTD" "$ACTUAL" > "$DIFF" \
		|| warn "Fileref mismatch; see\n- $EXPCTD\n- $ACTUAL\n- $DIFF"

	EXPCTD="$JSON_FILES.trimmed"
	ACTUAL="$DIR_FILES"
	DIFF="$RRDP_DIR/dirs.diff"

	ls -1 "$SANDBOX/workdir/https/$CAGE_ID" > "$ACTUAL"

	ck_inc
	diff -B "$EXPCTD" "$ACTUAL" > "$DIFF" \
		|| warn "Dir mismatch; see\n- $EXPCTD\n- $ACTUAL\n- $DIFF"
}
