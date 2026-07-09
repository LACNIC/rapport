# Rapport – Test Suite: RTR Request Queue
## Pipelining and Flood Protection

> **Scope:** This suite exercises that undefined territory. Fort enqueues incoming requests while a previous one is being handled, up to an internal limit of four simultaneous queued requests. Within that limit, Fort answers all queued requests in order. Beyond it, Fort assumes the client is either misbehaving or attempting a Denial of Service, logs an overflow message, empties the queue, and closes the TCP connection without answering any pending request. This is a **Fort-specific implementation decision**, not a normative requirement of RFC 8210.

---

## Test Cases

---

### bundled - `4-reqs-within-limit`

**Description:**
This test checks that Fort correctly handles four simultaneous Reset Query PDUs arriving in a single TCP packet — the maximum that fits within its internal queue limit without triggering an overflow. All four are enqueued before the worker thread can begin responding, and Fort must answer each one in order, producing four full Cache Response / data / End of Data cycles. This is the baseline that confirms Fort's pipelining works correctly for legitimate burst traffic below the overflow threshold.

---

### bundled - `5-reqs-overflow`

**Description:**
This test checks that Fort detects the overflow condition when five Reset Query PDUs arrive in a single TCP packet. The first four are enqueued normally; the fifth causes Fort to log the overflow message, which clears the entire request queue before releasing the internal queue. The worker thread finds an empty queue and sends no responses. Fort closes the TCP connection. The test asserts the overflow log message is present and that zero PDUs were sent.

---

### bundled - `error-mid-queue-no-reply`

**Description:**
This test checks Fort's response when a Reset Query, an Error Report, and a second Reset Query arrive together in a single TCP packet. Because all three PDUs are processed in one batch before any response can be sent, the Error Report interrupts the sequence before the first Reset Query is answered. Fort cannot respond to an Error Report with another Error Report, and it cannot answer the interrupted queries without first having handled the error, so it closes the connection without sending any PDUs. The test asserts zero PDUs and that the connection was closed.

---

### quick - `4-reqs-within-limit`

**Description:**
This test checks the same behavior as `bundled-4-reqs-within-limit` — four requests within the queue limit — but sends each Reset Query in its own TCP packet in rapid succession. The expected result is identical: four full response blocks. The distinction from `bundled-4-reqs-within-limit` is transport-level: the PDUs arrive in separate TCP segments rather than one, exercising the scenario where Fort receives queries quickly between poll iterations rather than all at once within a single iteration.

---

### quick - `10-reqs-overflow`

**Description:**
This test checks that Fort detects the overflow condition when ten Reset Query PDUs arrive in rapid succession as separate TCP packets. Unlike the bundled variant, the overflow fires at a non-deterministic point (whichever query happens to be the fifth simultaneous arrival in Fort's queue). Fort logs the overflow, clears the queue, and closes the connection. Because the overflow point is timing-dependent, Fort may have answered some queries before detecting it; the test therefore makes no assertion on a specific PDU count but applies two structural constraints when PDUs are received. First, the count must be a multiple of the PDUs-per-response value defined by the repository under test, confirming that Fort never cut a response cycle in half — a partial response would indicate a protocol error independent of the overflow. Second, the count must be strictly less than that same per-response value multiplied by the number of queries sent, confirming that the overflow was triggered before all queries could be answered — a full count would mean the overflow was never detected, which would contradict the log assertion. A count of zero (Fort closed before sending anything) satisfies both constraints trivially and skips the PDU checks. Because some `send_router_pdu` invocations may fail with "Server unreachable" once Fort has closed the connection, those errors are suppressed and do not constitute a test failure.

---

### quick - `error-mid-queue-1-reply`

**Description:**
This test checks Fort's response when a Reset Query, an Error Report, and a second Reset Query are sent as three separate TCP packets in rapid succession. Because each PDU travels in its own packet, Fort receives and begins responding to the first Reset Query before the Error Report arrives. Fort finishes that response (one full Cache Response / data / End of Data cycle), then closes the connection upon receiving the Error Report, without responding to the second Reset Query. The test asserts exactly one full response block and that the connection was subsequently closed.

---

*End of RTR Request Queue test suite — 6 test cases*
