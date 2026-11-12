#!/bin/sh

if [ -f "$APACHE2_DIR/apache2.pid" ]; then
	echo "Stopping apache2 $APACHE2_PORT"
	kill $(cat "$APACHE2_DIR/apache2.pid")
fi
