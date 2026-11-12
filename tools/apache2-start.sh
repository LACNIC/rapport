#!/bin/sh

# $1: Path to apache2 configuration file

wait_for_file() {
	# $1 = path to wait for, $2 = timeout in tenths of a second (100 = 10s)
	path_file="$1"
	timeout=100
	n=0
	while [ ! -f "$path_file" ]; do
		n=$((n + 1))
		test "$n" -le "$timeout" || return 1
		sleep 0.1
	done
}

mkdir -p "$APACHE2_DIR/content"
cp "$1" "$APACHE2_DIR/apache2.conf"

echo "Starting apache2 $APACHE2_PORT"
"$APACHE2" -f "${PWD}/$APACHE2_DIR/apache2.conf"

# TODO Seems naive. The PID file does not imply server readiness.
# Works fine for now tho.
wait_for_file "$APACHE2_DIR/apache2.pid" \
	|| fail "Timeout waiting for the Apache instance to start."
