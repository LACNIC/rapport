#!/bin/sh

#set -x     # Decomment to print all commands
#set -e     # Decomment to stop immediately on error

# If $1 exists, only tests involving a matching RD will be run.
ACCEPT_RD="$1"

case "$RP" in
	"fort2")
		export RP_BIN="$FORT"
		;;
	"routinator")
		export RP_BIN="$ROUTINATOR"
		;;
	"rpki-client")
		export RP_BIN="$RPKI_CLIENT"
		;;
	"rpki-prover")
		export RP_BIN="$RPKI_PROVER"
		;;
	*)
		echo "Unknown RP: $RP"
		echo '(Look up "$RP" in the README.)'
		return 1
		;;
esac

. rp/"$RP".sh
. tools/vars.sh
if [ $? -ne 0 ]; then
	exit 1
fi
tools/cleanup-sandbox.sh

RSYNC_PATH="--rsync-path sandbox/rsyncd/content"
RRDP_PATH="--rrdp-path sandbox/apache2/content/rrdp"
KEYS="--keys sandbox/keys"
PRINTS="-p csv"
#TIMES="--now 2025-01-01T00:00:00Z --later 2026-01-01T00:00:00Z"
BARRY="$BARRY $RSYNC_PATH $RRDP_PATH $KEYS $PRINTS"

APACHE_REQLOG="sandbox/apache2/logs/8443.log"
RSYNC_REQLOG="sandbox/rsyncd/rsyncd.log"

if [ -z "$MEMCHECK" ]; then
	MEMCHECK="$MEMCHECK_DEFAULT"
fi
# Note, if you set MEMCHECK=0 and override VALGRIND in the environment,
# you'll be able to define a custom container.
if [ "$MEMCHECK" -ne 0 ]; then
	VALGRIND="valgrind --error-exitcode=1 --leak-check=full \
		--show-leak-kinds=all --errors-for-leak-kinds=all \
		--track-origins=yes"
fi

SUCCESSES=0
FAILS=0

########################################################################

ck_result() {
	RESULT=$1
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: $2"
		FAILS=$((FAILS+1))
	fi
}

run_test() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	echo "Test: $TEST"
	export WORKSPACE="sandbox/tests/$TEST"

	rm -rf sandbox/apache2/content/*
	rm -rf sandbox/rsyncd/content/*
	echo > "$APACHE_REQLOG"
	echo > "$RSYNC_REQLOG"
	mkdir -p "$WORKSPACE/workdir"

	$BARRY --tal-path $(rp_tal_path) "rd/$TEST.rd" > "$WORKSPACE/barry.txt" 2>&1
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
		echo "$TEST: Barry returned $RESULT"
		FAILS=$((FAILS+1))
		return
	fi

	rp_run
	ck_result $? "$RP returned $RESULT."
}

# Checks the RP generated $1 VRPs.
# This test is redundant if you also do check_vrp_output(),
# but is more appropriate if the RP is supposed to generate 0 VRPs.
# $1: Expected VRP count
check_vrp_count() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	ROWS=$(wc -l < "$(rp_vrp_path)")
	ACTUAL=$((ROWS-1))
	test "$1" -eq "$ACTUAL"
	ck_result $? "Expected $1 VRP(s), $RP produced $ACTUAL"
}

# Checks the RP generated the $@ VRPs.
# $@: Sequence of VRPs in "PREFIX-MAXLEN => AS" format.
#     It must be sorted in accordance to `sort`'s default rules.
check_vrp_output() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	VRP_DIR="$WORKSPACE/vrp"
	EXPECTED="$VRP_DIR/expected.txt"
	ACTUAL="$VRP_DIR/actual.txt"
	DIFF="$VRP_DIR/diff.txt"
	mkdir -p "$VRP_DIR"

	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done
	# Lucky: All supported RPs print the same first 3 columns,
	# so there's no need for a callback.
	tail -n +2 "$(rp_vrp_path)" |
		awk -F, '{ printf "%s-%s => %s\n", $2, $3, $1 }' - |
		sort > "$ACTUAL"
	
	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF"
	ck_result $? "Unexpected VRPs; see $VRP_DIR"
}

# Checks the RP's output logfile contains a line that matches $3 regex string.
# Needs work, because it currently only supports Fort.
# $1: file to grep in
# $2: grep flags
# $3: regex to search
check_output() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi
	if [ "$RP" != "fort2" ]; then
		# Haven't figured out how this is going to work for other RPs
		return;
	fi

	grep -q $2 -- "$3" "sandbox/tests/$TEST/$1"
	ck_result $? "$1 does not contain '$3'"
}

# Checks the Apache server received the $@ sequence of requests (and nothing
# else).
# $@: Sequence of HTTP requests in "PATH HTTP_RESULT_CODE" format.
check_http_requests() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	APACHE_DIR="$WORKSPACE/apache2"
	EXPECTED="$APACHE_DIR/expected.log"
	ACTUAL="$APACHE_DIR/actual.log"
	DIFF="$APACHE_DIR/diff.txt"
	mkdir -p "$APACHE_DIR"

	cp "$APACHE_REQLOG" "$ACTUAL"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF"
	ck_result $? "Unexpected Apache request sequence; see $APACHE_DIR"
}

# Checks the rsync server received the $@ sequence of requests (and nothing
# else).
# $@: Sequence of rsync requests in "PATH" format.
check_rsync_requests() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	RSYNC_DIR="$WORKSPACE/rsync"
	EXPECTED="$RSYNC_DIR/expected.log"
	ACTUAL="$RSYNC_DIR/actual.log"
	DIFF="$RSYNC_DIR/diff.txt"
	mkdir -p "$RSYNC_DIR"

	grep -o "rsync on .* from localhost" "$RSYNC_REQLOG" > "$ACTUAL"
	for i in "$@"; do
		echo "rsync on $i from localhost" >> "$EXPECTED"
	done

	diff -B "$EXPECTED" "$ACTUAL" > "$DIFF"
	ck_result $? "Unexpected rsync request sequence; see $RSYNC_DIR"
}

########################################################################

tools/apache2-start.sh
tools/rsyncd-start.sh

export TEST="simple"
run_test
check_vrp_output \
	"101::/16-16 => AS1234" \
	"102::/16-16 => AS1234" \
	"1.1.0.0/16-16 => AS1234" \
	"1.2.0.0/16-16 => AS1234"
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
