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

	RD="rd/$TEST.rd"
	WORKSPACE="sandbox/tests/$TEST"
	TAL=$(rp_tal)

	rm -rf sandbox/apache2/content/*
	rm -rf sandbox/rsyncd/content/*
	echo > "$APACHE_REQLOG"
	echo > "$RSYNC_REQLOG"
	mkdir -p "$WORKSPACE/workdir"

	$BARRY --tal-path $TAL $RD > "$WORKSPACE/barry.txt" 2>&1
	RESULT=$?
	if [ $RESULT -ne 0 ]; then
		echo "$TEST: Barry returned $RESULT"
		FAILS=$((FAILS+1))
		return
	fi

	rp_run
	ck_result $? "$RP returned $RESULT."
}

# $1: Expected VRP count
ck_vrp_count() {
	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	ACTUAL=$(rp_count_vrps)
	test "$1" -eq "$ACTUAL"
	ck_result $? "Expected $1 VRP(s), $RP produced $ACTUAL"
}

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
	ck_result $? "Unexpected Apache request sequence; see $DIFF"
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
	ck_result $? "Unexpected rsync request sequence; see $DIFF"
}

########################################################################

tools/apache2-start.sh
tools/rsyncd-start.sh

export TEST="simple"
run_test
ck_vrp_count 1
check_http_requests \
	"/rrdp/ta.cer 200" \
	"/rrdp/notification.xml 200" \
	"/rrdp/notification.xml.snapshot 200"
#check_rsync_requests "rpki/"

export TEST="bad-roa-version"
run_test
ck_vrp_count 0
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
