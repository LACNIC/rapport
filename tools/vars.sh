#!/bin/sh

if [ -z "$BARRY" ]; then
	BARRY=~/git/barry/src/barry
fi
if [ -z "$FORT" ]; then
	FORT=~/git/fort/src/fort
fi
if [ -z "$APACHE2" ]; then
	APACHE2=/usr/sbin/apache2
fi
if [ -z "$RSYNC" ]; then
	RSYNC=rsync
fi

test_exists() {
	$1 > /dev/null
	if [ $? -ne 0 ]; then
		echo "'$1' returns nonzero."
		echo "Please adjust the '$2' environment variable."
		exit 1
	fi
}

test_exists "$BARRY --help" "BARRY"
test_exists "$FORT --help" "FORT"
test_exists "$APACHE2 -v" "APACHE2"
test_exists "$RSYNC --help" "RSYNC"
