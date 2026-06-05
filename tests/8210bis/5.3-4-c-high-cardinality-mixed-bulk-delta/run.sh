#!/bin/sh

. tools/checks.sh
. rp/$RP.sh

mkdir -p "$SANDBOX"
FILE="$SANDBOX/sorted-pdus.tmp"

# Generator functions (print to stdout, used in pipes)

vrps_rd1() {
	p=1; while [ "$p" -le 15 ]; do  # stable v4, maxlen=16
		printf '10.%d.0.0/16-16 => AS%d\n' "$p" "$((65536+p))"; p=$((p+1)); done
	p=16; while [ "$p" -le 25 ]; do # chgmaxln v4, maxlen=24
		printf '10.%d.0.0/16-24 => AS%d\n' "$p" "$((65536+p))"; p=$((p+1)); done
	p=26; while [ "$p" -le 84 ]; do # rd1-only v4 (pares), maxlen=16
		printf '10.%d.0.0/16-16 => AS%d\n' "$p" "$((65536+p))"; p=$((p+2)); done
	n=1; while [ "$n" -le 10 ]; do  # rd1-only v6
		printf '2001:db8:0:%x::/64-64 => AS%d\n' "$n" "$((65700+n))"; n=$((n+1)); done
}

vrps_rd2() {
	p=1; while [ "$p" -le 15 ]; do  # stable v4, maxlen=16
		printf '10.%d.0.0/16-16 => AS%d\n' "$p" "$((65536+p))"; p=$((p+1)); done
	p=16; while [ "$p" -le 25 ]; do # chgmaxln v4, maxlen=16 en rd2
		printf '10.%d.0.0/16-16 => AS%d\n' "$p" "$((65536+p))"; p=$((p+1)); done
	p=27; while [ "$p" -le 85 ]; do # rd2-only v4 (impares), maxlen=16
		printf '10.%d.0.0/16-16 => AS%d\n' "$p" "$((65536+p))"; p=$((p+2)); done
	n=11; while [ "$n" -le 20 ]; do # rd2-only v6
		printf '2001:db8:0:%x::/64-64 => AS%d\n' "$n" "$((65700+n))"; n=$((n+1)); done
}

aspas_rd1() {
	p=1; while [ "$p" -le 15 ]; do  # stable: [65000,65001]
		printf '%d:[65000,65001]\n' "$((0x0088000000+p*65536))"; p=$((p+1)); done
	k=0; while [ "$k" -le 9 ]; do   # changed v1: [64800+2k,64801+2k]
		printf '%d:[%d,%d]\n' "$((0x0088000000+(16+k)*65536))" \
			"$((64800+2*k))" "$((64801+2*k))"; k=$((k+1)); done
	p=26; while [ "$p" -le 84 ]; do # rd1-only (pares): [65200]
		printf '%d:[65200]\n' "$((0x0088000000+p*65536))"; p=$((p+2)); done
}

aspas_rd2() {
	p=1; while [ "$p" -le 15 ]; do  # stable: [65000,65001]
		printf '%d:[65000,65001]\n' "$((0x0088000000+p*65536))"; p=$((p+1)); done
	k=0; while [ "$k" -le 9 ]; do   # changed v2: [64900+k,64901+k]
		printf '%d:[%d,%d]\n' "$((0x0088000000+(16+k)*65536))" \
			"$((64900+k))" "$((64901+k))"; k=$((k+1)); done
	p=27; while [ "$p" -le 85 ]; do # rd2-only (impares): [65300]
		printf '%d:[65300]\n' "$((0x0088000000+p*65536))"; p=$((p+2)); done
}

# ─────────────────────────────────────────────────────────────────────────────
# STEP 1 — rd1: verify initial state
# ─────────────────────────────────────────────────────────────────────────────

run_barry "rd1"
start_rp
start_router

# check_vrps: 65 VRPs of rd1 (sorted lexicographic)
vrps_rd1 | sort > "$FILE"
set --; while IFS= read -r l; do set -- "$@" "$l"; done < "$FILE"
check_vrps "$@"

# check_aspas: 55 ASPAs from rd1 (sorted by decimal customerASID)
aspas_rd1 | sort > "$FILE"
set --; while IFS= read -r l; do set -- "$@" "$l"; done < "$FILE"
check_aspas "$@"

# reset-query: verify full cache rd1 via RTR (122 PDUs)
send_router_pdu "reset-query"

set -- "cache-response version 2 session [0-9]+ length 8"

# IPv4 — rd1-only (AS even 65562-65620, maxlen=16)
p=84; while [ "$p" -ge 26 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p-2)); done
# IPv4 — chgmaxln (AS 65552-65561, maxlen=24 en rd1)
p=25; while [ "$p" -ge 16 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 24 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p-1)); done
# IPv4 — stable (AS 65537-65551, maxlen=16)
p=15; while [ "$p" -ge 1 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p-1)); done

# IPv6 — rd1-only (AS 65701-65710, plen=64 maxlen=64)
n=10; while [ "$n" -ge 1 ]; do
	set -- "$@" "ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 64 maxlen 64 zero2 0 prefix $(printf '2001:db8:0:%x::' "$n") as $((65700+n))"
	n=$((n-1)); done

# ASPAs — stable (pos 1-15, providers=[65000,65001], length=20)
p=1; while [ "$p" -le 15 ]; do
	set -- "$@" "aspa-pdu       version 2 flags 1 zero 0 length 20 customer $((0x0088000000+p*65536)) providers \[ 65000 65001 \]"
	p=$((p+1)); done
# ASPAs — changed v1 (k=0..9, providers=[64800+2k,64801+2k], length=20)
k=0; while [ "$k" -le 9 ]; do
	p=$((16+k))
	set -- "$@" "aspa-pdu       version 2 flags 1 zero 0 length 20 customer $((0x0088000000+p*65536)) providers \[ $((64800+2*k)) $((64801+2*k)) \]"
	k=$((k+1)); done
# ASPAs — rd1-only (even 26-84, providers=[65200], length=16)
p=26; while [ "$p" -le 84 ]; do
	set -- "$@" "aspa-pdu       version 2 flags 1 zero 0 length 16 customer $((0x0088000000+p*65536)) providers \[ 65200 \]"
	p=$((p+2)); done

set -- "$@" "end-of-data    version 2 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"
check_pdus "$@"

# ─────────────────────────────────────────────────────────────────────────────
# STEP 2 — rd2 as delta: verify final state and 170 items of delta RTR
# ─────────────────────────────────────────────────────────────────────────────

new_step
create_delta "rd2"
revalidate_rp

# check_vrps: 65 VRPs from rd2 (sorted)
vrps_rd2 | sort > "$FILE"
set --; while IFS= read -r l; do set -- "$@" "$l"; done < "$FILE"
check_vrps "$@"

# check_aspas: 55 ASPAs of rd2 (sorted) — also checks via RTR reset-query
aspas_rd2 | sort > "$FILE"
set --; while IFS= read -r l; do set -- "$@" "$l"; done < "$FILE"
check_aspas "$@"


send_router_pdu "serial-query serial 1"

set -- \
	"serial-notify  version 2 session [0-9]+ length 12 serial 2" \
	"cache-response version 2 session [0-9]+ length 8"

# IPv4 δ — announcements rd2-only
p=85; while [ "$p" -ge 27 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p-2)); done

p=25; while [ "$p" -ge 16 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 1 plen 16 maxlen 16 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p-1)); done

# IPv4 δ — withdrawals rd1-only
p=16; while [ "$p" -le 25 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 24 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p+1)); done

p=26; while [ "$p" -le 84 ]; do
	set -- "$@" "ipv4-prefix    version 2 zero1 0 length 20 flags 0 plen 16 maxlen 16 zero2 0 prefix 10.$p.0.0 as $((65536+p))"
	p=$((p+2)); done

# IPv6 δ — 10 announcements rd2-only (AS 65711-65720)
n=20; while [ "$n" -ge 11 ]; do
	set -- "$@" "ipv6-prefix    version 2 zero1 0 length 32 flags 1 plen 64 maxlen 64 zero2 0 prefix $(printf '2001:db8:0:%x::' "$n") as $((65700+n))"
	n=$((n-1)); done

# IPv6 δ — 10 withdrawals rd1-only (AS 65701-65710)
n=1; while [ "$n" -le 10 ]; do
	set -- "$@" "ipv6-prefix    version 2 zero1 0 length 32 flags 0 plen 64 maxlen 64 zero2 0 prefix $(printf '2001:db8:0:%x::' "$n") as $((65700+n))"
	n=$((n+1)); done

# ASPA δ — changed: A(length=20,providers_v2)
k=0; while [ "$k" -le 9 ]; do
	set -- "$@" "aspa-pdu       version 2 flags 1 zero 0 length 20 customer $((0x88000000+(16+k)*65536)) providers \[ $((64900+k)) $((64901+k)) \]"
	k=$((k+1)); done

# ASPA δ — interleaved: W(rd1-only,even,length=12) + A(rd2-only,odd,length=16)
p=27; while [ "$p" -le 85 ]; do
	set -- "$@" "aspa-pdu       version 2 flags 1 zero 0 length 16 customer $((0x88000000+p*65536)) providers \[ 65300 \]"
	p=$((p+2)); done

p=26; while [ "$p" -le 84 ]; do
	set -- "$@" "aspa-pdu       version 2 flags 0 zero 0 length 12 customer $((0x88000000+p*65536))"
	p=$((p+2)); done

set -- "$@" "end-of-data    version 2 session [0-9]+ length 24 serial 2 refresh [0-9]+ retry [0-9]+ expire [0-9]+"
check_pdus "$@"

stop_router
stop_rp
