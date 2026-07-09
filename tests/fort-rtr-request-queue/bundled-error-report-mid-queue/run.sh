#!/bin/sh

. tools/checks.sh
. tests/$CATEGORY/checks.sh
. rp/$RP.sh
 
run_barry
start_rp
start_router
sleep 1 # TODO shouldn't be necessary
 
# Senndig the bundled query string reset-error-reset
send_bundled_router_pdus \
    "reset-query\nerror-report   version 2 error-code 0 length 16 encapsulated-pdu-length 0 error-text-length 0\nreset-query\n"

# Waiting for a validation message in the log.
# Fort must have responded with exactly ZERO PDUs before closing.
check_logfile fort1 -F "ERR: RTR client 127.0.0.1 responded with error PDU 'Corrupt Data'. Closing socket."
check_pdus
 
stop_router
stop_rp
