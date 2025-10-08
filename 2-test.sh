#!/bin/sh

#set -x     # Decomment to print all commands
#set -e     # Decomment to stop immediately on error

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

. rp/"$RP".sh
. tools/vars.sh
if [ $? -ne 0 ]; then
	exit 1
fi
tools/cleanup-sandbox.sh

export APACHE_REQLOG="sandbox/apache2/logs/8443.log"
export RSYNC_REQLOG="sandbox/rsyncd/rsyncd.log"

if [ -z "$MEMCHECK" ]; then
	MEMCHECK="$MEMCHECK_DEFAULT"
fi
# Note, if you set MEMCHECK=0 and override VALGRIND in the environment,
# you'll be able to define a custom container.
if [ "$MEMCHECK" -ne 0 ]; then
	export VALGRIND="valgrind --error-exitcode=1 --leak-check=full \
		--show-leak-kinds=all --errors-for-leak-kinds=all \
		--track-origins=yes"
fi

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
	echo > "$APACHE_REQLOG"
	echo > "$RSYNC_REQLOG"
	mkdir -p "$SANDBOX/workdir"

	$T/$TEST.sh || NFAILS=$((NFAILS+1))
	NTESTS=$((NTESTS+1))
	
	set +e # In case a test enables -e.
done

tools/rsyncd-stop.sh
tools/apache2-stop.sh

########################################################################

echo ""
echo "Successes: $((NTESTS-NFAILS))"
echo "Failures : $NFAILS"
