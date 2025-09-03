#!/bin/sh

PIDFILE=sandbox/rsyncd/rsyncd.pid

echo "Stopping rsyncd."
if [ -f "$PIDFILE" ]; then
	kill $(cat "$PIDFILE")
else
	echo "Expected running rsyncd, but $PIDFILE doesn't exist."
	exit 1
fi
