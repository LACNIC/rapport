# Rapport – Test Suite: RFC 6810
## The RPKI to Router Protocol (Version 0)
### Reference version: RFC 6810 (January 2013)

> **Scope:** Tests derived from RFC 6810 focus on the RPKI-to-Router (RTR)
> protocol version 0 that a cache uses to deliver validated prefix origin
> data — IPv4 and IPv6 VRPs — to routers. The cache server under test must
> correctly implement PDU structure enforcement, session and serial
> management, incremental and full update sequences, error handling, and the
> specific semantics of the Cache Has No Data Available and No Incremental
> Update Available error flows. RFC 6810 does not define Router Keys or ASPA
> records; those are introduced in RFC 8210 and 8210bis respectively and are
> out of scope for this suite.

> **Test identifiers:** Each test is identified by the **section number** of
> the main paragraph it relates to in RFC 6810 (e.g. `section 5.3` → `5.3`).
> When more than one test relates to the same section, a sub-index (`-a`,
> `-b`, `-c`, …) is appended (`5.3-a`, `5.3-b`, …).

---

## Key Concepts

| Concept | Section | Impact on cache server under test |
|---|---|---|
| Protocol Version is 0 throughout; no version negotiation defined in RFC 6810 | section 5.1 | Cache must reject PDUs with Version ≠ 0 with Error Code 4 |
| Session ID binds a Serial Number space to one cache instance | section 5.1, section 2 | Session ID mismatch must cause the cache to drop the session |
| Serial Number is a 32-bit strictly increasing unsigned integer; wrap-around via RFC 1982 | section 2, section 4 | Cache Reset must be issued when the requested serial is outside the available window |
| Reset Query requests the full active database; all payload PDUs must have Flags=1 | section 5.4, section 5.5 | Cache must send only announcements in response to Reset Query |
| Serial Query requests incremental changes since the given serial | section 5.3 | Cache responds with delta or Cache Reset if serial is out of window |
| Cache Has No Data Available is signaled with Error Report Error Code 2 | section 6.4, section 10 | Cache must not respond with payload PDUs when data is unavailable |
| Cache MUST send one and only one IPvX PDU per unique {Prefix, Len, Max-Len, ASN} at any time | section 5.6 | Duplicate ROAs must be coalesced; duplicate announcements trigger Error Code 7 |
| Error Report PDUs are fatal; session MUST be dropped | section 5.10, section 10 | Cache must log and drop the session for all fatal error codes |
| An Error Report MUST NOT be sent in response to an Error Report | section 5.10 | Cache must not reply with Error Report upon receiving one |

---

## Test Cases

---

### 4-1 — `serial-number-wraparound`

**Description:**
This test checks that the cache treats the Serial Number as a 32-bit strictly increasing unsigned integer that wraps from `0xFFFFFFFF` to `0`, and that it applies RFC 1982 Serial Number Arithmetic — not a naive unsigned comparison — when responding to a Serial Query. With the cache at serial `0xFFFFFFFF` and the router synchronized to it, the cache completes one validated update wrapping the serial to `0`. The router sends a Serial Query carrying `0xFFFFFFFF`; the cache MUST recognize that `0xFFFFFFFF` precedes `0` by a single increment and respond with a Cache Response, the one-increment delta, and an End of Data PDU carrying Serial Number `0`. The cache MUST NOT treat `0xFFFFFFFF` as newer than `0` nor emit a Cache Reset. A follow-up Serial Query at serial `0` MUST yield a null update, confirming `0` is the live current version.

---

### 5.2 — `serial-notify-session-id-consistency`

**Description:**
This test checks that after a successful validation cycle that increments the cache's Serial Number, the cache sends a Serial Notify PDU to all connected routers carrying the updated Serial Number and the current Session ID. The Session ID in the Serial Notify MUST match the Session ID previously established for the session, reassuring the router that the Serial Numbers remain commensurate and the cache session has not changed, per section 5.2. The router verifies that the Serial Number in the notify is strictly greater than the one carried in the previous End of Data PDU.

---

### 5.3-1 — `serial-query-incremental-update`

**Description:**
This test checks the nominal section 6.2 exchange path: the cache receives a Serial Query with the correct Session ID and a Serial Number from a previous valid exchange, and the cache has new data since that serial. The cache must respond with a Cache Response PDU carrying the current Session ID, followed by the set of all payload PDUs with Serial Numbers greater than the queried serial, and conclude with an End of Data PDU carrying the new Serial Number. The Session ID in the End of Data MUST match that of the Cache Response that began the sequence, per section 5.8.

---

### 5.3-2 — `serial-query-null-update`

**Description:**
This test checks that the cache correctly handles a Serial Query whose Serial Number equals the cache's current Serial Number — meaning the router is already fully up to date — by responding with a Cache Response PDU immediately followed by an End of Data PDU with no intervening payload PDUs. Per section 4, the null set is a valid response and the End of Data MUST still be sent.

---

### 5.3-3 — `serial-query-wrong-session-id`

**Description:**
This test checks that the cache detects a Session ID mismatch when a Serial Query arrives carrying a Session ID that does not match the Session ID established for the session. Per section 5.1: "If, at any time, either the router or the cache finds the value of the session identifier is not the same as the other's, they MUST completely drop the session and the router MUST flush all data learned from that cache." The cache must drop the session upon receiving such a Serial Query.

---

### 5.3-4 — `serial-query-serial-outside-window`

**Description:**
This test checks that the cache responds to a Serial Query whose Serial Number refers to a point in history no longer available in the cache's incremental update window — because the cache has cleaned up old delta data or the router waited too long between polls — by sending a Cache Reset PDU per section 6.3, informing the router that it cannot provide an incremental update from that serial. The router must then decide whether to issue a Reset Query or switch to a different cache.

---

### 5.4-1 — `reset-query-full-data-set`

**Description:**
This test checks the nominal section 6.1 start-or-restart sequence: the cache receives a Reset Query and responds with a Cache Response PDU, followed by all currently active payload PDUs — every record in the cache's database — each with the announce flag (lowest order bit of Flags) set to 1, and concludes with an End of Data PDU carrying the current Serial Number. The cache must not include any withdrawal PDUs (Flags=0) in a Reset Query response.

---

### 5.4-2 — `reset-query-no-data-available`

**Description:**
This test checks that the cache responds to a Reset Query with an Error Report PDU carrying Error Code 2 (No Data Available) when the cache has not yet completed its initial validation cycle and has no useful data available, per section 6.4. The cache MUST NOT respond with a Cache Response followed by an empty payload set; it must use the Error Report path to signal the temporary unavailability of data.

---

### 5.5-1 — `cache-response-session-id-in-serial-query`

**Description:**
This test checks that in response to a Serial Query, the Session ID in the cache's Cache Response PDU is identical to the Session ID the router used in its Serial Query, reassuring the router that the Serial Numbers are commensurate and the cache session has not changed, per section 5.5.

---

### 5.6-1-a — `ipv4-prefix-announce-flag-reset-query`

**Description:**
This test checks that all IPv4 Prefix PDUs delivered by the cache in response to a Reset Query have the announce flag (lowest order bit of the Flags field) set to 1, per section 5.5 ("in this case, the withdraw/announce field in the payload PDUs MUST have the value 1"). The cache must not deliver any IPv4 Prefix PDU with Flags=0 during a Reset Query response.

---

### 5.6-1-b — `ipv4-prefix-announce-flag-serial-query`

**Description:**
This test checks that during an incremental update (Serial Query response), the cache correctly sets the Flags field to 1 for newly announced IPv4 Prefix PDUs and to 0 for withdrawn IPv4 Prefix PDUs, and that withdrawal PDUs carry the exact same {Prefix, Len, Max-Len, ASN} tuple as the previously announced record, effectively deleting the router's stored VRP entry.

---

### 5.6-2 — `ipv4-prefix-coalescing-equivalent-roas`

**Description:**
This test checks that the cache delivers one and only one IPv4 Prefix PDU for a unique {Prefix, Len, Max-Len, ASN} tuple even when its validated dataset holds multiple distinct ROAs that map to that same router-level tuple — a real RPKI occurrence during certificate reissuance or address-ownership transfer where the ROAs differ only in validation path. Per section 5.6: "The cache server MUST ensure that it has told the router client to have one and only one IPvX PDU for a unique {Prefix, Len, Max-Len, ASN} at any one point in time." A router receiving the same tuple twice SHOULD raise Error Code 7 (Duplicate Announcement Received).

---
### 5.6-3 — `ipv4-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update covering multiple serial increments, the cache correctly delivers an IPv4 Prefix PDU with the Flags field set to 1 (announce) for each IPv4 VRP that was newly added to the RPKI dataset within the queried serial range, with correct Prefix, Prefix Length, Max Length, and Autonomous System Number fields, and that the cache merges multiple changes for the same {Prefix, Len, Max-Len, ASN} tuple into at most one announcement.
---

### 5.6-4 — `ipv4-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update covering multiple serial increments, the cache correctly delivers an IPv4 Prefix PDU with the Flags field set to 0 (withdraw) for each IPv4 VRP that was removed from the RPKI dataset within the queried serial range, with the exact same {Prefix, Len, Max-Len, ASN} tuple as the previously announced record, effectively deleting the router's stored VRP entry.

---

### 5.7-1-a — `ipv6-prefix-announce-flag-reset-query`

**Description:**
This test checks that all IPv6 Prefix PDUs delivered by the cache in response to a Reset Query have the announce flag set to 1, per section 5.5, and that the cache does not include any IPv6 Prefix PDU with Flags=0 in a Reset Query response. The test uses a repository containing both IPv4 and IPv6 VRPs to confirm the flag constraint applies uniformly to both payload types.

---

### 5.7-1-b — `ipv6-prefix-announce-flag-serial-query`

**Description:**
This test checks that during an incremental update, the cache correctly sets the Flags field to 1 for newly announced IPv6 Prefix PDUs and to 0 for withdrawn IPv6 Prefix PDUs, with all 128-bit prefix bits beyond the prefix length zeroed, and with the withdrawal carrying the exact same {Prefix, Len, Max-Len, ASN} tuple as the previously announced record.

---

### 5.7-2 — `ipv6-prefix-coalescing-equivalent-roas`

**Description:**
This test checks that the cache delivers one and only one IPv6 Prefix PDU for a unique {Prefix, Len, Max-Len, ASN} tuple when multiple distinct ROAs in the RPKI map to that same tuple, applying the same coalescing requirement of section 5.6 to IPv6 payload PDUs, per the analogy stated in section 5.7 ("Analogous to the IPv4 Prefix PDU").

---

### 5.7-3 — `ipv6-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update covering multiple serial increments, the cache correctly delivers an IPv6 Prefix PDU with the Flags field set to 1 (announce) for each IPv6 VRP newly added within the queried serial range, with correct 128-bit Prefix, Prefix Length (0..128), Max Length (0..128), and Autonomous System Number fields, with unused prefix bits zeroed, merging multiple changes for the same {Prefix, Len, Max-Len, ASN} tuple into at most one announcement.
---

### 5.7-4 — `ipv6-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update covering multiple serial increments, the cache correctly delivers an IPv6 Prefix PDU with the Flags field set to 0 (withdraw) for each IPv6 VRP removed within the queried serial range, with the exact same {Prefix, Len, Max-Len, ASN} tuple as the previously announced record, effectively deleting the router's stored IPv6 VRP entry.

---

### 5.8-1 — `end-of-data-session-id-consistency`

**Description:**
This test checks that the Session ID in the cache's End of Data PDU is identical to the Session ID in the Cache Response that began the same payload sequence, per section 5.8 ("The Session ID MUST be the same as that of the corresponding Cache Response that began the, possibly null, sequence of data PDUs"). The test covers both the Reset Query and Serial Query paths.

---

### 5.10-1 — `error-report-corrupt-data`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 0 ("Corrupt Data"). The simulated router sends an Error Report PDU with code 0 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition that would lead a router to detect corruption (e.g. a Session ID mismatch in a cache-originated PDU). What is under test is that the cache correctly identifies the error, records it in its log so that an operator can act on it, and closes the connection on receipt without replying with an Error Report PDU of its own.

---

### 5.10-2 — `error-report-withdrawal-of-unknown-record`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 6 ("Withdrawal of Unknown Record"). The simulated router sends an Error Report PDU with code 6 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition (a withdrawal PDU with Flags=0 for a {Prefix, Len, Max-Len, ASN} tuple absent from the router's database). What is under test is that the cache correctly identifies the error, records it in its log, and closes the connection on receipt.

---

### 5.10-3 — `error-report-duplicate-announcement`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 7 ("Duplicate Announcement Received"). The simulated router sends an Error Report PDU with code 7 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition (an announcement PDU for a {Prefix, Len, Max-Len, ASN} tuple already active in the router). What is under test is that the cache correctly identifies the error, records it in its log, and closes the connection on receipt.

---

### 5.10-4 — `cache-sends-error-code-5-unsupported-pdu-type`

**Description:**
This test checks that when a router sends a PDU with a PDU Type value not defined in RFC 6810 (e.g. type `0x63`), the cache responds with a well-formed Error Report PDU carrying Error Code 5 ("Unsupported PDU Type") and drops the session, per section 10 ("Unsupported PDU Type (fatal)").

---

### 9-1-a — `fragmented-reset-query`

**Description:**
This test checks that the cache correctly handles a Reset Query PDU that arrives fragmented across multiple TCP segments — i.e., the complete 8-octet PDU is not received in a single read — by reassembling it correctly before processing, and responding with the expected Cache Response followed by the full active dataset and an End of Data PDU, without errors caused by partial PDU processing. The PDU is split into two 4-byte TCP segments with a brief delay between them to prevent the OS from coalescing them via the Nagle algorithm. A cache that processes PDUs without accounting for TCP stream boundaries would either fail to parse the PDU or produce an incorrect response.

---

### 9-1-b — `fragmented-serial-query`

**Description:**
This test checks that the cache correctly handles a Serial Query PDU that arrives fragmented across multiple TCP segments — i.e., the complete 12-octet PDU is split across at least two reads — by fully reassembling it before processing, and responding with the expected incremental update (or Cache Reset if the serial is outside the window) without errors attributable to partial PDU reception. A full Reset Query is first issued to establish the session and learn the current Session ID and Serial Number; the Serial Query is then sent split into two 6-byte TCP segments with a brief delay between them to prevent Nagle coalescing. A cache that does not correctly buffer and reassemble the TCP stream before parsing would either reject the query or produce an error response.

---

*End of RFC 6810 test suite — 26 test cases*
