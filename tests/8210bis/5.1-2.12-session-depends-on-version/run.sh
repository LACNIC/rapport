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
	# Extract session from the output
	grep -F "cache-response" "$SANDBOX/barry-rtr.stdout" |
		awk '{ print $5 }' > "$PDU_DIR/$2-v$1"

	stop_router
	rm "$SANDBOX/barry-rtr.stdout"
}

run_barry rd
start_rp
request_session 0 "router1"
request_session 1 "router1"
request_session 2 "router1"
request_session 0 "router2"
request_session 1 "router2"
request_session 2 "router2"
stop_rp

SESSION_R1V0=$(cat "$PDU_DIR/router1-v0")
ck_inc && test ! -z "$SESSION_R1V0" || fail "Missing router1-v0 session. See $PDU_DIR"
SESSION_R1V1=$(cat "$PDU_DIR/router1-v1")
ck_inc && test ! -z "$SESSION_R1V1" || fail "Missing router1-v1 session. See $PDU_DIR"
SESSION_R1V2=$(cat "$PDU_DIR/router1-v2")
ck_inc && test ! -z "$SESSION_R1V2" || fail "Missing router1-v2 session. See $PDU_DIR"
SESSION_R2V0=$(cat "$PDU_DIR/router2-v0")
ck_inc && test ! -z "$SESSION_R2V0" || fail "Missing router2-v0 session. See $PDU_DIR"
SESSION_R2V1=$(cat "$PDU_DIR/router2-v1")
ck_inc && test ! -z "$SESSION_R2V1" || fail "Missing router2-v1 session. See $PDU_DIR"
SESSION_R2V2=$(cat "$PDU_DIR/router2-v2")
ck_inc && test ! -z "$SESSION_R2V2" || fail "Missing router2-v2 session. See $PDU_DIR"

ck_inc && test "$SESSION_R1V0" = "$SESSION_R2V0" || fail "Routers received different v0 sessions. See $PDU_DIR"
ck_inc && test "$SESSION_R1V1" = "$SESSION_R2V1" || fail "Routers received different v1 sessions. See $PDU_DIR"
ck_inc && test "$SESSION_R1V2" = "$SESSION_R2V2" || fail "Routers received different v2 sessions. See $PDU_DIR"

ck_inc && test "$SESSION_R1V0" -ne "$SESSION_R1V1" || fail "RTRv0 session equals RTRv1 session. See $PDU_DIR"
ck_inc && test "$SESSION_R1V1" -ne "$SESSION_R1V2" || fail "RTRv1 session equals RTRv2 session. See $PDU_DIR"
ck_inc && test "$SESSION_R1V0" -ne "$SESSION_R1V2" || fail "RTRv0 session equals RTRv2 session. See $PDU_DIR"
