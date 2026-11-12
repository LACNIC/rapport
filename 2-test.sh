#!/bin/sh

# $1: Categories of the test(s) you want to run, separated by whitespace.
#     Omit to run all categories.
# $2: Names of the tests you want to run, separated by whitespace.
#     Omit to run all tests in $1.

#set -x

# Run as `FORCE=1 ./2-test.sh` to skip this question.
if [ -z "$1" -a -z "$FORCE" ]; then
	echo -n "You sure you want to run everything? (y/*) "
	read FORCE
	test "$FORCE" = "y" || exit 0
fi

case "$RP" in
	fort*)
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
. tools/checks.sh
tools/cleanup-sandbox.sh

NSUCCESSES=0
NFAILS=0
NSKIPS=0
NUNKNOWNS=0

# Turn off RP, barry, apache & rsync on Ctrl+C
trap 'tools/cleanup.sh; exit 1' INT

export APACHE2_PORT="8443"
export APACHE2_DIR="sandbox/apache2/$APACHE2_PORT"
tools/apache2-start.sh "tools/apache2.conf"
export RSYNC_PORT="8873"
tools/rsyncd-start.sh

stop_custom_apaches() {
	cp -rp "sandbox/apache2" "$SANDBOX/apache2"

	for i in sandbox/apache2/*; do
		PORT="$(basename "$i")"
		if [ "$PORT" != "$APACHE2_PORT" ]; then
			APACHE2_PORT="$PORT" \
				APACHE2_DIR="sandbox/apache2/$PORT" \
				tools/apache2-stop.sh
			rm -rf "$i"
		fi
	done
}

run_test() {
	test -d "$1" || return 0

	# Assume category "C" and test name "N"
	export SRCDIR="$1"                      # tests/C/N
	export SANDBOX="sandbox/$SRCDIR/latest" # sandbox/tests/C/N/latest
	export TESTID="${SRCDIR#tests/}"        # C/N
	export CATEGORY="${TESTID%/*}"          # C
	export TEST="${TESTID#*/}"              # N
	export STEP_PREV="0"
	export STEP="1"                         # 1

	# Don't mind this one.
	export BARRY_RTR_SK="sandbox/$SRCDIR/barry-rtr.sk"

	echo "Test: $TESTID"

	:> "$APACHE2_DIR/main.log"
	:> "$APACHE2_DIR/requests.log"
	rm -rf "$APACHE2_DIR/content/"*
	:> "$RSYNC_REQLOG"
	clear_rsync_modules
	mkdir -p "$SANDBOX/workdir"

	"$SRCDIR"/run.sh
	case "$?" in
	0)  tools/post-test.sh
	    case "$?" in
	    0)  NSUCCESSES=$((NSUCCESSES+1))  ;;
	    1)  NFAILS=$((NFAILS+1))          ;;
	    3)  NSKIPS=$((NSKIPS+1))          ;;
	    *)  NUNKNOWNS=$((NUNKNOWNS+1))    ;;
	    esac
	    ;;
	1)  NFAILS=$((NFAILS+1))          ;;
	3)  NSKIPS=$((NSKIPS+1))          ;;
	*)  NUNKNOWNS=$((NUNKNOWNS+1))    ;;
	esac

	stop_rp
	stop_router
	stop_custom_apaches
	cp -rp "sandbox/rsyncd" "$SANDBOX/rsyncd"
}


FIND_ARGS="-mindepth 1 -maxdepth 1 -printf %f\n -type d"
if [ -z "$1" ]; then
	CATEGORIES=$(find -L tests $FIND_ARGS | sort -V)
else
	CATEGORIES="$1"
fi
for CATEGORY in $CATEGORIES; do
	if [ -z "$2" ]; then
		TESTS=$(find -L "tests/$CATEGORY" $FIND_ARGS | sort -V)
	else
		TESTS="$2"
	fi
	for T in $TESTS; do
		run_test "tests/$CATEGORY/$T"
	done
done


tools/rsyncd-stop.sh
tools/apache2-stop.sh

echo ""
echo "Successes: $NSUCCESSES"
echo "Failures : $NFAILS"
echo "Skipped  : $NSKIPS"
echo "Unknown  : $NUNKNOWNS"
echo ""
echo "Total checks: $(cat sandbox/counters/total.txt | wc -c)"
echo "Warnings    : $(cat sandbox/counters/warns.txt | wc -c)"
echo ""
echo "Please remember that the test suite might be at fault for issues."
echo "Also, the tests are presently built around Fort."
echo "(Other RPs might disagree on what the correct results should be.)"
