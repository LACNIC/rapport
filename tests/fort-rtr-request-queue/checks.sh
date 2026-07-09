#!/bin/sh

# send_router_pdu() variant.
# Sends multiple PDUs in a single TCP packet.
# Each PDU must contain a trailing newline!
send_bundled_router_pdus() {
	test ! -z "$BARRY_RTR_PID" || fail "The router is not running."
	printf "$@" | $BARRY-ncu "$BARRY_RTR_SK"
}

# Verifies that Fort sent only complete response cycles (multiples of
# PDUS_PER_RESPONSE) and fewer than MAX_QUERIES full cycles, confirming
# that the overflow was triggered before all queries were answered.
# A count of zero (Fort closed before sending anything) is a valid outcome
# and skips both checks.
check_partial_responses() {
	ppu="$1"   # PDUs per complete response cycle
	max="$2"   # maximum number of queries that should have been answered
 
    	count=$(wc -l < "$SANDBOX/barry-rtr.stdout")
    	test "$count" -gt 0 || return 0
 
    	max_pdus=$((ppu * max))
    	remainder=$((count % ppu))
 
    	ck_inc
    	test "$remainder" -eq 0 \
        	|| fail "Received $count PDUs, not a multiple of $ppu (remainder: $remainder)"
 
    	ck_inc
    	test "$count" -lt "$max_pdus" \
        	|| fail "Received $count PDUs; must be less than $max_pdus ($ppu * $max queries)"
}