#!/bin/sh

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
