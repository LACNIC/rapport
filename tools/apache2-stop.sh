#!/bin/sh

PIDFILE=sandbox/apache2/apache2.pid

echo "Stopping apache2."
if [ -f "$PIDFILE" ]; then
	kill $(cat "$PIDFILE")
else
	echo "Expected running apache, but $PIDFILE doesn't exist."
	exit 1
fi
