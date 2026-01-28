#!/bin/sh

# $1: Category of the test(s) you want to run.
#     Send nothing to run all categories.
# $2: Name of the test you want to run.
#     Send nothing to run all tests in $1.

#set -x     # Decomment to print all commands

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

NSUCCESSES=0
NFAILS=0
NSKIPS=0
NUNKNOWNS=0

tools/apache2-start.sh
tools/rsyncd-start.sh

run_test() {
	export SRCDIR="$1"		 # tests/cat/simple
	export SANDBOX="sandbox/$SRCDIR" # sandbox/tests/cat/simple
	export TESTID="${SRCDIR#tests/}" # cat/simple
    	export CATEGORY="${TESTID%/*}"	 # cat
	export TEST="${TESTID#*/}"	 # simple

	echo "Test: $TESTID"

	rm -rf sandbox/apache2/content/*
	rm -rf sandbox/rsyncd/content/*
	:> "$APACHE_REQLOG"
	:> "$RSYNC_REQLOG"
	mkdir -p "$SANDBOX/workdir"

	"$SRCDIR"/run.sh
	case "$?" in
	0)  NSUCCESSES=$((NSUCCESSES+1))  ;;
	1)  NFAILS=$((NFAILS+1))          ;;
	3)  NSKIPS=$((NSKIPS+1))          ;;
	*)  NUNKNOWNS=$((NUNKNOWNS+1))    ;;
	esac
}

if [ -z "$1" ]; then
	for CATEGORY in tests/*; do
		for T in "$CATEGORY"/*; do
			run_test "$T"
		done
	done
elif [ -z "$2" ]; then
	for T in "tests/$1"/*; do
		run_test "$T"
	done
else
	run_test "tests/$1/$2"
fi

tools/rsyncd-stop.sh
tools/apache2-stop.sh

echo ""
echo "Successes: $NSUCCESSES"
echo "Failures : $NFAILS"
echo "Skipped  : $NSKIPS"
echo "Unknown  : $NUNKNOWNS"
echo ""
echo "Total checks: $(cat sandbox/checks/total.txt | wc -c)"
echo "Warnings    : $(cat sandbox/checks/warns.txt | wc -c)"
echo ""
echo "Please remember that the test suite might be at fault for issues."
echo "Also, the tests are presently built around Fort."
echo "(Other RPs might disagree on what the correct results should be.)"
