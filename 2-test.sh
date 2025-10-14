#!/bin/sh

#set -x     # Decomment to print all commands

# $1 is the name of the test you want to run. Send nothing to run all tests.
if [ -z "$1" ]; then
	TESTS=tests/*
else
	TESTS="tests/$1"
fi

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

. rp/$RP.sh
. tools/vars.sh || exit 1
tools/cleanup-sandbox.sh

NTESTS=0
NFAILS=0

tools/apache2-start.sh
tools/rsyncd-start.sh

for T in $TESTS; do
	export TEST="$(basename $T)"
	export SRCDIR="$T"
	export SANDBOX="sandbox/tests/$TEST"

	echo "Test: $TEST"

	rm -rf sandbox/apache2/content/*
	rm -rf sandbox/rsyncd/content/*
	:> "$APACHE_REQLOG"
	:> "$RSYNC_REQLOG"
	mkdir -p "$SANDBOX/workdir"

	$T/$TEST.sh || NFAILS=$((NFAILS+1))
	NTESTS=$((NTESTS+1))
done

tools/rsyncd-stop.sh
tools/apache2-stop.sh

echo ""
echo "Successes: $((NTESTS-NFAILS))"
echo "Failures : $NFAILS"
