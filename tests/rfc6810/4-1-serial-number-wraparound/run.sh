#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry
run_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512"

# TODO: The case of each validator must be analyzed.
# We override the serial number of FORT
sed -Ei"" \
    's/serial:[0-9]+ /serial:4294967294 /g' \
    "sandbox/tests/$CATEGORY/$TEST/latest/workdir/rtr/index"

# We execute the validation waiting for the serial 4294967295 
run_barry rd
start_rp
start_router

check_vrps \
	"1.1.0.0/24-24 => AS64512"

sleep 2

send_router_pdu "reset-query version 0"
check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 4294967295"
 
# We execute another validation waiting for the serial 0
new_step
create_delta rd2
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513"

send_router_pdu "reset-query version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 0" \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 0"

# We execute another validation waiting for the serial 1
new_step
create_delta rd3
revalidate_rp

check_vrps \
	"1.1.0.0/24-24 => AS64512" \
	"1.2.0.0/24-24 => AS64513" \
	"1.3.0.0/24-24 => AS64514"

send_router_pdu "reset-query version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 1" \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.3.0.0 as 64514" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.0.0 as 64512" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

send_router_pdu "serial-query serial 4294967295 version 0"
check_pdus \
    	"cache-response version 0 session [0-9]+ length 8" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.3.0.0 as 64514" \
    	"ipv4-prefix    version 0 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.2.0.0 as 64513" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

stop_router
stop_rp
