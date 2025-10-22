#!/bin/sh

check_exists() {
	if ! $1 > /dev/null 2> /dev/null; then
		echo "'$1' returns nonzero."
		echo "Please adjust the '$2' environment variable."
		exit 1
	fi
}


if [ -z "$BARRY" ]; then
	export BARRY=barry
fi
check_exists "$BARRY --help" "BARRY"


if [ -z "$APACHE2" ]; then
	export APACHE2=apache2
fi
check_exists "$APACHE2 -v" "APACHE2"
export APACHE_REQLOG="sandbox/apache2/logs/8443.log"


if [ -z "$RSYNC" ]; then
	export RSYNC=rsync
fi
check_exists "$RSYNC --help" "RSYNC"
export RSYNC_REQLOG="sandbox/rsyncd/rsyncd.log"


if [ -z "$RP_BIN" ]; then
	export RP_BIN="$RP_BIN_DEFAULT"
fi
check_exists "$RP_BIN -V" "ROUTINATOR"
