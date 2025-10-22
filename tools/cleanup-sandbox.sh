#!/bin/sh

# Kill Apache, if it was left hanging in a previous run.
if [ -f "sandbox/apache2/apache2.pid" ]; then
	kill $(cat "sandbox/apache2/apache2.pid")
fi
# Kill rsync, if it was left hanging in a previous run.
if [ -f "sandbox/rsyncd/rsyncd.pid" ]; then
	kill $(cat "sandbox/rsyncd/rsyncd.pid")
fi

rm -fr "sandbox/apache2/logs"
rm -f  "sandbox/rsyncd/rsyncd.log"
rm -fr "sandbox/tests/simple/apache2"
rm -f  "sandbox/tests/simple/routinator.log"
rm -f  "sandbox/tests/simple/stderr.txt"
rm -fr "sandbox/tests/simple/vrp"
rm -f  "sandbox/tests/simple/vrps.csv"
rm -fr "sandbox/tests/simple/workdir"
