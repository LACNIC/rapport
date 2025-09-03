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
PRINTS="-vvp csv"
#TIMES="--now 2025-01-01T00:00:00Z --later 2026-01-01T00:00:00Z"
BARRY="$BARRY $RSYNC_PATH $RRDP_PATH $KEYS $PRINTS"

FORT_CACHE="--local-repository sandbox/cache"
FORT_NLOG="--log.enabled --log.level debug"
FORT_VLOG="--validation-log.enabled --validation-log.level debug"
FORT="$FORT --mode standalone $FORT_CACHE $FORT_NLOG $FORT_VLOG"

SUCCESSES=0
FAILS=0

########################################################################

run_test() {
	TEST="$1"
	TAL="sandbox/tal/$TEST.tal"
	RD="rd/$TEST.rd"

	if [ ! -z "$ACCEPT_RD" -a "$TEST" != "$ACCEPT_RD" ]; then
		return
	fi

	rm -rf sandbox/apache2/content/*
	rm -rf sandbox/rsyncd/content/*

	$BARRY --tal-path $TAL $RD \
		>  sandbox/output/$TEST.barry.stdout.log \
		2> sandbox/output/$TEST.barry.stderr.log
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: Barry returned $RESULT"
		FAILS=$((FAILS+1))
	fi

	$FORT --tal $TAL \
		>  sandbox/output/$TEST.rp.stdout.log \
		2> sandbox/output/$TEST.rp.stderr.log
	RESULT=$?
	if [ $RESULT -eq 0 ]; then
		SUCCESSES=$((SUCCESSES+1))
	else
		echo "$TEST: Fort returned $RESULT"
		FAILS=$((FAILS+1))
	fi
}

########################################################################

tools/apache2-start.sh
tools/rsyncd-start.sh

run_test "simple"

tools/rsyncd-stop.sh
tools/apache2-stop.sh

########################################################################

echo "Successes: $SUCCESSES"
echo "Failures : $FAILS"
