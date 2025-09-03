#!/bin/sh

. tools/vars.sh

echo "Starting rsyncd ($RSYNC)."
$RSYNC --daemon --config="sandbox/rsyncd/rsyncd.conf"
