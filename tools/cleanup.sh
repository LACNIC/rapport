#!/bin/sh

if [ ! -z "$RP_PID" ]; then
	echo "Stopping $RP."
	kill "$RP_PID"
fi

if [ ! -z "$BARRY_RTR_PID" ]; then
	echo "Stopping barry."
	kill "$BARRY_RTR_PID"
fi

PIDFILE=sandbox/apache2/apache2.pid
if [ -f "$PIDFILE" ]; then
	echo "Stopping apache2."
	kill $(cat "$PIDFILE")
fi

PIDFILE=sandbox/rsyncd/rsyncd.pid
if [ -f "$PIDFILE" ]; then
	echo "Stopping rsyncd."
	kill $(cat "$PIDFILE")
fi
