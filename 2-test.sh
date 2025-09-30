#!/bin/sh

#set -x     # Print commands
#set -e     # Stop immediately on error

# If $1 exists, only tests involving a matching RD will be run.
ACCEPT_RD="$1"

. tools/vars.sh
tools/cleanup-sandbox.sh

RSYNC_PATH="--rsync-path sandbox/rsyncd/content"
RRDP_PATH="--rrdp-path sandbox/apache2/content/rrdp"
KEYS="--keys sandbox/keys"
PRINTS="-p csv"
#TIMES="--now 2025-01-01T00:00:00Z --later 2026-01-01T00:00:00Z"
BARRY="$BARRY $RSYNC_PATH $RRDP_PATH $KEYS $PRINTS"

FORT="$FORT --mode standalone $FORT_CACHE"

APACHE_REQLOG="sandbox/apache2/logs/8443.log"
RSYNC_REQLOG="sandbox/rsyncd/rsyncd.log"

LEAK_CHECK="--leak-check=full --show-leak-kinds=all --errors-for-leak-kinds=all"
VALGRIND="valgrind --error-exitcode=1 $LEAK_CHECK --track-origins=yes"

SUCCESSES=0
FAILS=0

########################################################################

run_test() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	echo "Test: $TEST"

	RD="rd/$TEST.rd"
	WORKSPACE="sandbox/tests/$TEST"
	TAL="$WORKSPACE/tal.txt"

	rm -rf sandbox/apache2/content/*
	rm -rf sandbox/rsyncd/content/*
	echo > "$APACHE_REQLOG"
	echo > "$RSYNC_REQLOG"
	mkdir -p "$WORKSPACE/cache"

	$BARRY --tal-path $TAL $RD > "$WORKSPACE/barry.txt" 2>&1
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
		echo "$TEST: Barry returned $RESULT"
		FAILS=$((FAILS+1))
		return
	fi

	$VALGRIND $FORT --tal $TAL \
		--local-repository "$WORKSPACE/cache" \
		--report.path "$WORKSPACE/report.txt" \
		> "$WORKSPACE/fort.log" 2>&1
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: Fort returned $RESULT"
		FAILS=$((FAILS+1))
	fi
}

# $1: file to grep in
# $2: grep flags
# $3: regex to search
check_output() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	grep -q $2 -- "$3" "sandbox/tests/$TEST/$1"
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: $1 does not contain '$3'"
		FAILS=$((FAILS+1))
	fi
}

# $1: Expected VRP count
check_vrp_count() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	check_output "fort.log" -Fx "INF: - Valid ROAs: $1"
}

# Arguments: Expected request log lines
check_http_requests() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	WORKSPACE="sandbox/tests/$TEST/apache2"
	EXPECTED="$WORKSPACE/expected.log"
	ACTUAL="$WORKSPACE/actual.log"
	DIFF="$WORKSPACE/diff.txt"
	mkdir -p "$WORKSPACE"

	cp "$APACHE_REQLOG" "$ACTUAL"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF"
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: Unexpected Apache request sequence; see $DIFF"
		FAILS=$((FAILS+1))
	fi
}

# Arguments: Expected request log lines
check_rsync_requests() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	WORKSPACE="sandbox/tests/$TEST/rsync"
	EXPECTED="$WORKSPACE/expected.log"
	ACTUAL="$WORKSPACE/actual.log"
	DIFF="$WORKSPACE/diff.txt"
	mkdir -p "$WORKSPACE"

	grep -o "rsync on .* from localhost" "$RSYNC_REQLOG" > "$ACTUAL"
	for i in "$@"; do
		echo "rsync on $i from localhost" >> "$EXPECTED"
	done

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF"
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: Unexpected rsync request sequence; see $DIFF"
		FAILS=$((FAILS+1))
	fi
}

########################################################################

tools/apache2-start.sh
tools/rsyncd-start.sh

export TEST="simple"
run_test
check_vrp_count 1
check_http_requests \
	"/rrdp/ta.cer 200" \
	"/rrdp/notification.xml 200" \
	"/rrdp/notification.xml.snapshot 200"
#check_rsync_requests "rpki/"

export TEST="bad-roa-version"
run_test
check_vrp_count 0
check_output "report.txt" -F "ROA's version (2) is nonzero."
check_http_requests \
	"/rrdp/ta.cer 200" \
	"/rrdp/notification.xml 200" \
	"/rrdp/notification.xml.snapshot 200"

tools/rsyncd-stop.sh
tools/apache2-stop.sh

########################################################################

echo ""
echo "Successes: $SUCCESSES"
echo "Failures : $FAILS"
