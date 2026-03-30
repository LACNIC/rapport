#!/bin/sh

PIDFILE=sandbox/rsyncd/rsyncd.pid

# If $1 equals "1", the script was called within the logic of a test; in this case, the message is not printed. This is only for special cases.
if [ "$1" != "1" ]; then
	echo "Stopping rsyncd."
fi

if [ -f "$PIDFILE" ]; then
	kill $(cat "$PIDFILE")
else
	echo "Expected running rsyncd, but $PIDFILE doesn't exist."
	exit 1
fi
