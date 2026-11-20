#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

export EEIPS="obj.content.certificates.0.tbsCertificate.extensions.ip.extnValue"
export SOIPS="obj.content.encapContentInfo.eContent.ipAddrBlocks"
export SOAS="obj.content.encapContentInfo.eContent.asId"

echo_roa_file() {
	echo "  $NROAS.roa"
	NROAS=$((NROAS+1))
}

echo_roa_node() {
	echo "[node: $NROAS.roa]"
	NROAS=$((NROAS+1))
	#PFX=$(shuf -i 4-32 -n 1)
	#MLN=$(shuf -i "$PFX-32" -n 1)
	#ASN=$(shuf -i 1-4294967295 -n 1)
	echo '$EEIPS = [' "$1/$2" ']'
	echo '$SOIPS = [' "$1/$2-$3" ']'
	echo '$SOAS = ' "$4"
	echo
}

create_rd() {
	echo "ta.cer"
	
	NROAS=0
	for i in $1; do echo_roa_file; done
	for i in $2; do echo_roa_file; done
	for i in $3; do echo_roa_file; done
	for i in $4; do echo_roa_file; done
	for i in $(seq 1 6); do echo_roa_file; done
	echo

	NROAS=0
	for i in $1; do
		echo_roa_node "$i.0.0.0" 24 24 10000
	done

	echo_roa_node "176.0.0.0" 24 24 3000
	for i in $2; do
		echo_roa_node "192.0.0.0" 4 "$i" 2000
	done
	echo_roa_node "208.0.0.0" 4 4 1000

	echo_roa_node "224.0.0.0" 15 15 3000
	for i in $3; do
		echo_roa_node "224.0.0.0" "$i" 16 2000
	done
	echo_roa_node "224.0.0.0" 4 17 1000

	echo_roa_node "224.0.0.0" 15 18 3000
	for i in $4; do
		echo_roa_node "224.0.0.0" 16 18 "$i"
	done
	echo_roa_node "224.0.0.0" 17 18 1000
}

test -f "$SRCDIR/rd1" || create_rd \
	"16 32 64 80 96 144 160" \
	"5 6 8 9 10 13 14" \
	"5 6 8 9 10 13 14" \
	"1000 1001 1003 1004 1005 1008 1009" \
	> "$SRCDIR/rd1"

test -f "$SRCDIR/rd2" || create_rd \
	"48 80 96 112 128 144" \
	"7 9 10 11 12 13" \
	"7 9 10 11 12 13" \
	"1002 1004 1005 1006 1007 1008" \
	> "$SRCDIR/rd2"

# Step 1

run_barry "rd1"
start_rp
start_router

send_router_pdu "reset-query"
check_cache_response 0 1 \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 17 maxlen 18 zero2 0 prefix 224.0.0.0 as 1000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1009" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1008" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1005" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1004" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1003" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1001" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 15 maxlen 18 zero2 0 prefix 224.0.0.0 as 3000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 17 zero2 0 prefix 224.0.0.0 as 1000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 14 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 13 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 10 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 9 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 8 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 6 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 5 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 15 maxlen 15 zero2 0 prefix 224.0.0.0 as 3000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 4 zero2 0 prefix 208.0.0.0 as 1000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 14 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 13 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 10 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 9 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 8 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 6 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 5 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 176.0.0.0 as 3000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 160.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 144.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 96.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 80.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 64.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 32.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 16.0.0.0 as 10000"

# Step 2

new_step
create_delta "rd2"
revalidate_rp

send_router_pdu "serial-query serial 1"
check_cache_response 1 2 \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1007" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1006" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1002" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 12 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 11 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 7 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 12 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 11 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 4 maxlen 7 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 128.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 112.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 24 maxlen 24 zero2 0 prefix 48.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 16.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 32.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 64.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 24 maxlen 24 zero2 0 prefix 160.0.0.0 as 10000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 4 maxlen 5 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 4 maxlen 6 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 4 maxlen 8 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 4 maxlen 14 zero2 0 prefix 192.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 5 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 6 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 8 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 14 maxlen 16 zero2 0 prefix 224.0.0.0 as 2000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1000" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1001" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1003" \
  "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 18 zero2 0 prefix 224.0.0.0 as 1009"

stop_router
stop_rp
