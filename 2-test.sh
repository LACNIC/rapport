#!/bin/sh

#set -x     # Decomment to print all commands

export RP="routinator"
export RP_BIN="$ROUTINATOR"
export RP_BIN_DEFAULT="routinator"

. tools/vars.sh || exit 1
tools/cleanup-sandbox.sh

NSUCCESSES=0
NFAILS=0
NWARNS=0
NSKIPS=0
NUNKNOWNS=0

tools/apache2-start.sh
tools/rsyncd-start.sh

#for T in $TESTS; do
	export TEST="simple"
	export SANDBOX="sandbox/tests/$TEST"

	mkdir -p "$SANDBOX/workdir"

	tests/$TEST.sh
	case "$?" in
	0)  NSUCCESSES=$((NSUCCESSES+1))  ;;
	1)  NFAILS=$((NFAILS+1))          ;;
	2)  NWARNS=$((NWARNS+1))          ;;
	3)  NSKIPS=$((NSKIPS+1))          ;;
	*)  NUNKNOWNS=$((NUNKNOWNS+1))    ;;
	esac
#done

tools/rsyncd-stop.sh
tools/apache2-stop.sh

echo ""
echo "Successes: $NSUCCESSES"
echo "Failures : $NFAILS"
echo "Warnings : $NWARNS"
echo "Skipped  : $NSKIPS"
echo "Unknown  : $NUNKNOWNS"
echo ""
echo "Please remember that the test suite might be at fault for issues."
echo "Also, the tests are presently built around Fort."
echo "(Other RPs might disagree on what the correct results should be.)"
