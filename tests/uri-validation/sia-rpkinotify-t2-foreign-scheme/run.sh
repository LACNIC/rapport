#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp "--rsync.enabled=false"

check_logfile fort2 -F "TRC: URI 'ftp://localhost:8443/sia-rpkinotify-t2-foreign-scheme/notif-ca.xml': Unknown scheme"

check_vrps
