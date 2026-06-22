#!/bin/sh

. tools/checks.sh
. rp/$RP.sh


# Create test repository
run_barry
# Run Fort on the test repository
start_rp
# Start test router, connect it to Fort
start_router


# Sanitize: Check Fort produced the intended VRPs.
check_vrps "1.0.0.0/8-8 => AS1234" "100::/8-8 => AS1234"


# Send a reset query from the test router to Fort.
# We'll be overriding the RTR version, because Fort 1.6.8 only supports RTRv0
# and v1, but Rapport's default is v2.
send_router_pdu "reset-query version 1"
# Check exact Cache Response PDU flow.
# Validate RTR reached serial 1 (in the end-of-data) and returns the expected
# prefix PDUs.
check_pdus \
	"cache-response version 1 session [0-9]+ length 8" \
	"ipv4-prefix    version 1 zero1 0 length 20 flags 1 plen 8 maxlen 8 zero2 0 prefix 1.0.0.0 as 1234" \
	"ipv6-prefix    version 1 zero1 0 length 32 flags 1 plen 8 maxlen 8 zero2 0 prefix 100:: as 1234" \
	"end-of-data    version 1 session [0-9]+ length 24 serial 1 refresh [0-9]+ retry [0-9]+ expire [0-9]+"


# Ok, the environment has been prepared and seems correct.
# Now let's send the bugged serial query.
send_router_pdu "serial-query version 1 serial 0x80000001"
# Validate Fort returns a Cache Reset.
# If Fort returns something else, this validation should result in test failure.
check_pdus "cache-reset    version 1 zero 0 length 8"


# Clean up
stop_router
stop_rp
