#!/bin/sh

# 8210bis-25, section 5.1:
# 
# > To reduce the risk of confusion,
# > cache servers SHOULD NOT use the same Session ID across multiple
# > protocol versions

. tools/checks.sh
. rp/$RP.sh

PDU_DIR="$SANDBOX/pdu"
mkdir -p "$PDU_DIR"
rm -f "$PDU_DIR"/*

request_session() {
	start_router
	sleep 1 # TODO should not be necessary

	send_router_pdu "reset-query version $1"

	wait_pdus 4
	grep -F "cache-response" "$SANDBOX/barry-rtr.stdout" |
		awk '{ print $5 }' > "$PDU_DIR/v$1"
	truncate -s 0 "$SANDBOX/barry-rtr.stdout"

	stop_router
}

run_barry rd
start_rp
request_session 0
request_session 1
request_session 2
stop_rp

SESSION_V0=$(cat "$PDU_DIR/v0")
SESSION_V1=$(cat "$PDU_DIR/v1")
SESSION_V2=$(cat "$PDU_DIR/v2")

ck_inc
test ! -z "$SESSION_V0" || fail "RTRv0 session was not recorded"
ck_inc
test ! -z "$SESSION_V1" || fail "RTRv1 session was not recorded"
ck_inc
test ! -z "$SESSION_V2" || fail "RTRv2 session was not recorded"
ck_inc
test "$SESSION_V0" -ne "$SESSION_V1" ||
	fail "RTRv0 session equals RTRv1 session. See $PDU_DIR"
ck_inc
test "$SESSION_V1" -ne "$SESSION_V2" ||
	fail "RTRv1 session equals RTRv2 session. See $PDU_DIR"
ck_inc
test "$SESSION_V0" -ne "$SESSION_V2" ||
	fail "RTRv0 session equals RTRv2 session. See $PDU_DIR"
