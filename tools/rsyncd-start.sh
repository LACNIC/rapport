#!/bin/sh

# If $1 equals "1", the script was called within the logic of a test; in this case, the message is not printed. This is only for special cases.
if [ "$1" != "1" ]; then
    echo "Starting rsyncd ($RSYNC)."
fi

$RSYNC --daemon --config="sandbox/rsyncd/rsyncd.conf"
