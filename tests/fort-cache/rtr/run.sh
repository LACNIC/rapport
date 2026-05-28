#!/bin/sh

. "tools/checks.sh"
. "rp/$RP.sh"

check_rtr_index() {
	RTR_DIR="$SANDBOX/rtridx"
	EXPECTED="$RTR_DIR/regex.idx"
	ACTUAL="$RTR_DIR/actual.idx"
	DIFF="$RTR_DIR/diff.txt"
	mkdir -p "$RTR_DIR"

	:> "$EXPECTED"
	for i in "$@"; do
		echo "$i" >> "$EXPECTED"
	done

	cp "$SANDBOX/workdir/rtr/index" "$ACTUAL"

	ck_inc
	while read A; do
		test "$#" -ne 0 ||
			fail "Unexpected RTR index; see $RTR_DIR"
		echo "$A" | grep -Eqx "$1" - ||
			fail "Unexpected RTR index; see $RTR_DIR"
		shift
	done < "$ACTUAL"
}

run_barry
start_rp
check_vrps "101:1::/120-120 => AS1234" "1.1.1.0/24-24 => AS1234"
check_aspas "33554432:[0]"
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:1 date:.+"

new_step # 2
create_delta
start_rp
check_vrps "101:2::/120-120 => AS1234" "1.1.2.0/24-24 => AS1234"
check_aspas "33554432:[0]"
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:2 date:.+" \
	"serial:1 date:.+"

new_step # 3
create_delta
start_rp
check_vrps "101:3::/120-120 => AS1234" "1.1.3.0/24-24 => AS1234"
check_aspas "33554432:[0]"
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:3 date:.+" \
	"serial:2 date:.+" \
	"serial:1 date:.+"

new_step # 4
sed -i"" \
	's/serial:2 date:.*/serial:2 date:2000-10-10T00:00:00Z/g' \
	"$SANDBOX/workdir/rtr/index"
create_delta
start_rp
start_router
sleep 1 # TODO this shouldn't be necessary
send_router_pdu "reset-query"
check_cache_response 0 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 33554432 providers [ 0 ]" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 120 maxlen 120 zero2 0 prefix 101:4:: as 1234"
send_router_pdu "serial-query serial 1"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.1.0 as 1234" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 120 maxlen 120 zero2 0 prefix 101:1:: as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 120 maxlen 120 zero2 0 prefix 101:4:: as 1234"
send_router_pdu "serial-query serial 2"
check_pdus "cache-reset    version 2 zero 0 length 8"
send_router_pdu "serial-query serial 3"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.3.0 as 1234" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 120 maxlen 120 zero2 0 prefix 101:3:: as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 120 maxlen 120 zero2 0 prefix 101:4:: as 1234"
send_router_pdu "serial-query serial 4"
check_cache_response 0
stop_router
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:4 date:.+" \
	"serial:3 date:.+" \
	"serial:1 date:.+"
check_report fort1 -F "Dropping expired serial: 2"

new_step # 5
create_delta
start_rp
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:5 date:.+" \
	"serial:4 date:.+" \
	"serial:3 date:.+" \
	"serial:1 date:.+"

new_step # 6
create_delta
start_rp --server.deltas.lifetime=2
start_router
sleep 1 # TODO this shouldn't be necessary
send_router_pdu "reset-query"
check_cache_response 0 \
	"aspa-pdu       version 2 flags 1 zero 0 length 16 customer 33554432 providers [ 0 ]" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 120 maxlen 120 zero2 0 prefix 101:6:: as 1234"
send_router_pdu "serial-query serial 1"
check_pdus "cache-reset    version 2 zero 0 length 8"
send_router_pdu "serial-query serial 2"
check_pdus "cache-reset    version 2 zero 0 length 8"
send_router_pdu "serial-query serial 3"
check_pdus "cache-reset    version 2 zero 0 length 8"
send_router_pdu "serial-query serial 4"
check_cache_response 0 \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 1.1.4.0 as 1234" \
	"ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 1.1.6.0 as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 120 maxlen 120 zero2 0 prefix 101:4:: as 1234" \
	"ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 120 maxlen 120 zero2 0 prefix 101:6:: as 1234"
stop_router
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:6 date:.+" \
	"serial:5 date:.+" \
	"serial:4 date:.+"
check_report fort1 -F "Dropping serial by FIFO: 3"
check_report fort1 -F "Dropping serial by FIFO: 1"

new_step # 7
sed -i"" \
	's/serial:\(.\) date:.*/serial:\1 date:2000-10-10T00:00:00Z/g' \
	"$SANDBOX/workdir/rtr/index"
create_delta
start_rp
stop_rp
check_rtr_index "session:[0-9]+" \
	"serial:1 date:.+"
check_report fort1 -F "Dropping expired serial: 6"
check_report fort1 -F "Dropping expired serial: 5"
check_report fort1 -F "Dropping expired serial: 4"
