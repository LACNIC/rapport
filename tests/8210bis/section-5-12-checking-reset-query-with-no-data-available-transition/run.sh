#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

# This script does not perform any tests; it is only a transition to restart the rsyncd daemon normally.

sleep 5
tools/rsyncd-stop.sh "1"
sleep 2
tools/rsyncd-start.sh "1"
