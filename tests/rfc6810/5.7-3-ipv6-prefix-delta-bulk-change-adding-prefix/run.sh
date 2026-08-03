#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

run_barry rd1
start_rp "--server.deltas.lifetime" "4"
start_router

check_vrps \
	"100:1000::/20-20 => AS1000" \
	"100:2000::/20-20 => AS1000" \
	"100::/20-20 => AS1000"

sleep 2

send_router_pdu "reset-query version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:2000:: as 1000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:1000:: as 1000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:: as 1000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 1"

# Processing serial 2
new_step
create_delta rd2
revalidate_rp

check_vrps \
	"100:1000::/20-20 => AS1000" \
	"100:2000::/20-20 => AS1000" \
	"100::/20-20 => AS1000" \
	"100:3000::/20-20 => AS2000" \
	"100:4000::/20-20 => AS2000" \
	"100:5000::/20-20 => AS2000"	

send_router_pdu "serial-query serial 1 version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 2" \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 2"

# Processing serial 3
new_step
create_delta rd3
revalidate_rp

check_vrps \
	"100:1000::/20-20 => AS1000" \
	"100:2000::/20-20 => AS1000" \
	"100::/20-20 => AS1000" \
	"100:3000::/20-20 => AS2000" \
	"100:4000::/20-20 => AS2000" \
	"100:5000::/20-20 => AS2000" \
	"100:6000::/20-20 => AS3000" \
	"100:7000::/20-20 => AS3000" \
	"100:8000::/20-20 => AS3000"	

send_router_pdu "serial-query serial 1 version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 3" \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 3"

send_router_pdu "serial-query serial 2 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 3"

# Processing serial 4
new_step
create_delta rd4
revalidate_rp

check_vrps \
	"100:1000::/20-20 => AS1000" \
	"100:2000::/20-20 => AS1000" \
	"100::/20-20 => AS1000" \
	"100:3000::/20-20 => AS2000" \
	"100:4000::/20-20 => AS2000" \
	"100:5000::/20-20 => AS2000" \
	"100:6000::/20-20 => AS3000" \
	"100:7000::/20-20 => AS3000" \
	"100:8000::/20-20 => AS3000" \
	"100:9000::/20-20 => AS4000" \
	"100:a000::/20-20 => AS4000" \
	"100:b000::/20-20 => AS4000"

send_router_pdu "serial-query serial 1 version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 4" \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 4"

send_router_pdu "serial-query serial 2 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 4"

send_router_pdu "serial-query serial 3 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 4"

# Processing serial 5
new_step
create_delta rd5
revalidate_rp

check_vrps \
	"100:1000::/20-20 => AS1000" \
	"100:2000::/20-20 => AS1000" \
	"100::/20-20 => AS1000" \
	"100:3000::/20-20 => AS2000" \
	"100:4000::/20-20 => AS2000" \
	"100:5000::/20-20 => AS2000" \
	"100:6000::/20-20 => AS3000" \
	"100:7000::/20-20 => AS3000" \
	"100:8000::/20-20 => AS3000" \
	"100:9000::/20-20 => AS4000" \
	"100:a000::/20-20 => AS4000" \
	"100:b000::/20-20 => AS4000" \
	"100:c000::/20-20 => AS5000" \
	"100:d000::/20-20 => AS5000" \
	"100:e000::/20-20 => AS5000"

send_router_pdu "serial-query serial 1 version 0"
check_pdus \
	"serial-notify  version 0 session [0-9]+ length 12 serial 5" \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:5000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:4000:: as 2000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:3000:: as 2000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 5"

send_router_pdu "serial-query serial 2 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:8000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:7000:: as 3000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:6000:: as 3000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 5"

send_router_pdu "serial-query serial 3 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:b000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:a000:: as 4000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:9000:: as 4000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 5"


send_router_pdu "serial-query serial 4 version 0"
check_pdus \
	"cache-response version 0 session [0-9]+ length 8" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:e000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:d000:: as 5000" \
	"ipv6-prefix    version 0 zero1 0 length 32 flags 1 plen 20 maxlen 20 zero2 0 prefix 100:c000:: as 5000" \
	"end-of-data    version 0 session [0-9]+ length 12 serial 5"

stop_router
stop_rp
