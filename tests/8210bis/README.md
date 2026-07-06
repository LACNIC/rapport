# Rapport – Test Suite: draft-ietf-sidrops-8210bis
## The RPKI to Router Protocol, Version 2
### Reference version: draft-ietf-sidrops-8210bis-25

> **Scope:** Tests derived from this draft focus on the RPKI-to-Router (RTR) protocol that a cache uses to deliver validated RPKI data — IPv4/IPv6 prefix VRPs, Router Keys, and ASPA records — to routers. The cache server under test must correctly implement protocol version negotiation, PDU structure enforcement, session and serial management, incremental and full update sequences, and the specific semantics of ASPA and prefix payload PDUs including their delta (announce/withdraw) mechanics.

> **Test identifiers:** Each test is identified by the **paragraph anchor** of the main paragraph it relates to in `8210bis-25` (e.g. `#section-4-5` → `4-5`). When more than one test relates to the same paragraph, a sub-index (`-a`, `-b`, `-c`, …) is appended (`4-5-a`, `4-5-b`, …).

---

## Key Concepts

| Concept | Section | Impact on cache server under test |
|---|---|---|
| Protocol versions 0, 1, and 2 coexist; version is negotiated per session | section 7 | Cache must downgrade or reject based on router's offered version |
| Session ID binds a Serial Number space to one cache instance | section 5.1, section 2 | Session ID mismatch must cause Error Report and session teardown |
| Serial Number is a 32-bit strictly increasing counter; wrap-around applies | section 2, section 4, section 5.1 | Cache Reset must be issued when serial is outside the available window |
| Reset Query requests the full active database; Serial Query requests incremental changes | section 5.3, section 5.4 | Cache must respond correctly to each query type |
| Cache Has No Data Available is signaled with Error Report PDU | section 8.4 | Cache must not respond with payload PDUs when data is not yet available |
| PDU Length MUST NOT exceed 65,535 octets | section 5.1 | Fragmented or oversized PDUs must be handled or rejected |
| ASPA PDU announcement MUST contain at least one Provider AS; withdrawal MUST have no Provider list and Length == 12 | section 5.12 | Malformed ASPA PDUs must trigger Error Code 9 |
| For a given Customer AS, the router MUST see at most one active ASPA from a cache at any time | section 5.12 | Cache must merge multiple RPKI ASPA records into one PDU |
| Cache MUST merge announce/withdraw for same prefix/AS into minimal VRP | section 5.6 | Delta changes must be coalesced before delivery |
| Multiple distinct ROAs sharing one {Prefix, Len, Max-Len, AS} must produce exactly one VRP | section 5.6, section 5.7 | Cache must coalesce equivalent ROAs (cert reissuance, ownership transfer) so the router holds one VRP per tuple |
| Flags field lowest-order bit: 1 = announce, 0 = withdraw | section 5.1 | Incorrect flag values produce wrong router state |

---

## Test Cases

---

### 4-5 - `serial-number-wraparound-at-2pow32-boundary`

**Description:**
This test checks that the cache treats the Serial Number as a 32-bit strictly increasing unsigned integer that wraps from 2^32-1 (`0xFFFFFFFF`) to 0, and that it uses RFC1982 Serial Number Arithmetic — not a naive unsigned comparison — when computing the changes "since" the serial in a Serial Query. With the cache at serial `0xFFFFFFFF` and the router synchronised to it, the cache completes one validated update, wrapping its serial to `0` with a minimal delta. The router then sends a Serial Query  carrying `0xFFFFFFFF`. The cache MUST recognise that `0xFFFFFFFF` precedes `0` by a single increment — not that it is ahead — and respond with a Cache Response, the one-increment delta (withdraw before announce), and an End of Data PDU carrying Serial Number `0`. It MUST NOT treat `0xFFFFFFFF` as newer than `0` (returning an empty delta) nor emit a Cache Reset, since the requested serial is still within the window. A follow-up Serial Query at serial `0` then yields a null delta, confirming `0` is the live current version and not an uninitialised or reset state.

---

### 5.1-2.10 - `serial-query-with-incorrect-session-id`

**Description:**
This test checks that the cache detects a Session ID mismatch when a Serial Query arrives carrying a Session ID that does not match the Session ID previously established for the session, and responds by immediately terminating the session with an Error Report PDU carrying Error Code 0 ("Corrupt Data"), causing the router to flush all data learned from that cache.

---

### 5.1-2.12 - `session-depends-on-version`

**Description:**
This test checks that the cache binds the Session ID to the negotiated protocol version, so that sessions established at different versions are distinct even when served by the same cache. The cache is probed with a Reset Query at protocol versions 0, 1, and 2 by two independent routers, and the Session ID carried in each Cache Response is compared. For a given version, both routers MUST receive the same Session ID (it identifies the cache's session for that version, independent of which router asks); across versions, the same cache MUST issue different Session IDs (v0 ≠ v1 ≠ v2). This follows from sessions being specific to a protocol version: a Serial Number is commensurate only when Protocol Version, Session ID, and Serial Number all match, so cache servers SHOULD NOT reuse a Session ID across versions, and routers MUST treat sessions with different Protocol Version fields as separate even if the Session ID happens to coincide.

---

### 5.3-3 - `serial-query-with-serial-equal-to-server-serial`

**Description:**
This test checks that the cache correctly responds to a Serial Query whose Serial Number field is equal to the cache's current Serial Number — meaning the router is already fully up to date — by sending a Cache Response followed immediately by an End of Data PDU with no intervening payload PDUs, correctly signaling that there are no changes to deliver.

---

### 5.3-4-a - `aspa-net-zero-delta-across-multiple-serials`

**Description:**
This test checks that the cache coalesces intermediate ASPA changes across multiple serial increments and returns a net-zero delta — an empty payload set — when the queried range withdraws and then re-announces a record with identical content. ASPA A is active at serial 1, withdrawn at serial 2, and re-announced unchanged at serial 3; a Serial Query at serial 1 MUST therefore yield a Cache Response immediately followed by an End of Data PDU with no intervening payload PDUs, since the net change for Customer AS A is zero. The router retains ASPA A unchanged, its final table identical to the pre-query state.

---

### 5.3-4-b - `roa-net-zero-delta-across-multiple-serials`

**Description:**
This test checks that the cache coalesces intermediate IPv4/IPv6 Prefix VRP changes across multiple serial increments and returns a net-zero delta — an empty payload set — when the queried range withdraws and then re-announces a ROA with an identical `{Prefix, Len, Max-Len, AS}` tuple. ROA R is active at serial 1, withdrawn at serial 2, and re-announced unchanged at serial 3; a Serial Query at serial 1 MUST yield a Cache Response immediately followed by an End of Data PDU with no intervening payload PDUs, since the net change for the tuple is zero. The router retains ROA R unchanged, its final table identical to the pre-query state.

---

### 5.3-4-c - `high-cardinality-mixed-bulk-delta`

**Description:**
This test checks that the cache correctly produces a large-scale incremental update spanning all three payload PDU types — IPv4 Prefix, IPv6 Prefix, and ASPA — within a single serial increment, with no omissions, duplicates, or ordering violations. The two validated snapshots are constructed so that the sorted record lists interleave additions and removals (every other entry changes between snapshots), stressing all branches of the cache's internal sort-and-diff algorithm.

It also verifies the distinct update semantics per payload type: a VRP `{Prefix, Len, Max-Len, AS}` tuple change is expressed as a withdrawal of the old tuple followed by an announcement of the new one, whereas an ASPA provider-list change is expressed as a single replacement announcement (`Flags=1`) with no prior withdrawal. The expected delta totals 170 payload PDUs — 70 ASPA (10 modified announcements, 30 withdrawals, 30 new announcements), 80 IPv4 Prefix (10 withdraw + 10 announce for Max-Len changes, 30 withdrawals, 30 announcements), and 20 IPv6 Prefix (10 withdrawals, 10 announcements) — delivered with all withdrawals before announcements for the IP Prefix PDUs. The router's resulting table MUST match the serial-2 dataset exactly: 55 ASPAs, 55 IPv4 VRPs, and 10 IPv6 VRPs.

---

### 5.6-3-a - `ipv4-prefix-delta-simple-change-adding-prefix`

**Description:**
This test checks that during a simple incremental update covering a single serial increment, the cache correctly delivers an IPv4 Prefix PDU with the Flags field set to 1 (announce) for a newly added IPv4 VRP, with all fields correctly populated including a Prefix whose unused bits are zeroed, and that the cache has not delivered a prior withdrawal for the same tuple in the same delta.

---

### 5.6-3-b - `ipv4-prefix-delta-simple-change-updating-as`

**Description:**
This test checks that during a simple incremental update, the cache correctly represents a change to the Autonomous System Number associated with an existing IPv4 prefix by delivering a withdrawal PDU for the old {Prefix, Len, Max-Len, old-AS} tuple followed by an announcement PDU for the new {Prefix, Len, Max-Len, new-AS} tuple, and that the cache does not attempt to deliver these as a single in-place update, since the {Prefix, Len, Max-Len, AS} tuple is the primary key for VRP identity.

---

### 5.6-3-c - `ipv4-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers an IPv4 Prefix PDU with the Flags field set to 1 (announce) for each IPv4 VRP that was newly added to the RPKI dataset within the queried serial range, with correct Prefix, Prefix Length, Max Length, and Autonomous System Number fields, and that the cache merges multiple changes for the same {Prefix, Len, Max-Len, AS} tuple into at most one announcement.

---

### 5.6-3-d - `ipv4-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers an IPv4 Prefix PDU with the Flags field set to 0 (withdraw) for each IPv4 VRP that was removed from the RPKI dataset within the queried serial range, with the exact same {Prefix, Len, Max-Len, AS} tuple as the previously announced record, effectively deleting the router's stored VRP entry.

---

### 5.6-5 - `equivalent-roas-coalesced-to-single-vrp`

**Description:**
This test checks that the cache delivers one and only one IPvX VRP for a unique `{Prefix, Len, Max-Len, AS}` tuple even when its validated dataset holds multiple distinct ROAs that map to that same router-level tuple — a real RPKI occurrence during certificate reissuance or an address-ownership transfer up the validation chain, where the ROAs differ only in validation path (important to the RPKI, not to the router). With ROA-A and ROA-B (different CAs/paths) both authorizing `{10.1.0.0/16-16, AS 10001}` present at once, a Reset Query MUST yield exactly one IPv4 Prefix PDU (`Flags=1`) for the tuple — not two — and the router holds a single entry (a router receiving the tuple twice SHOULD raise Error Code 7). Across a reissuance where ROA-A is removed but the equivalent ROA-B remains, the Serial Query response MUST contain no IPv4 Prefix PDU for the tuple: the VRP stays continuously present and the change is invisible to the router. The same behaviour applies to IPv6 VRPs (section 5.7).

---

### 5.7-3-a - `ipv6-prefix-delta-simple-change-adding-prefix`

**Description:**
This test checks that during a simple incremental update covering a single serial increment, the cache correctly delivers an IPv6 Prefix PDU with the Flags field set to 1 (announce) for a newly added IPv6 VRP, with all 128-bit prefix bits beyond the prefix length zeroed, and that the cache ensures the router holds one and only one VRP for the unique {Prefix, Len, Max-Len, AS} tuple at that point in time.

---

### 5.7-3-b - `ipv6-prefix-delta-simple-change-updating-as`

**Description:**
This test checks that during a simple incremental update, the cache correctly represents a change to the Autonomous System Number associated with an existing IPv6 prefix by delivering a withdrawal PDU for the old {Prefix, Len, Max-Len, old-AS} tuple followed by an announcement PDU for the new {Prefix, Len, Max-Len, new-AS} tuple, and that the withdrawal is delivered before the announcement in accordance with the ordering requirements for IP Prefix PDUs.

---

### 5.7-3-c - `ipv6-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers an IPv6 Prefix PDU with the Flags field set to 1 (announce) for each IPv6 VRP newly added within the queried serial range, with correct 128-bit Prefix, Prefix Length (0..128), Max Length (0..128), and Autonomous System Number fields, and with unused prefix bits zeroed, merging multiple changes for the same tuple into at most one announcement.

---

### 5.7-3-d - `ipv6-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers an IPv6 Prefix PDU with the Flags field set to 0 (withdraw) for each IPv6 VRP removed within the queried serial range, with the exact same {Prefix, Len, Max-Len, AS} tuple as the previously announced record, effectively deleting the router's stored IPv6 VRP entry.

---

### 5.9-2 - `serial-query-with-serial-outside-of-window`

**Description:**
This test checks that the cache responds to a Serial Query whose Serial Number refers to a point in history that is no longer available in the cache's incremental update window — because the cache has since cleaned up old delta data or the router waited too long between polls — by sending a Cache Reset PDU, informing the router that it cannot provide an incremental update from that serial and must fall back to a Reset Query.

---

### 5.12-6 - `multiple-aspa-records-unioned-to-single-pdu`

**Description:**
This test checks that when the cache's validated data holds multiple distinct valid ASPA records for the same Customer AS, it forms the union of their Provider AS sets and delivers exactly one ASPA PDU for that Customer AS — so the router sees at most one active ASPA per Customer AS from the cache. With record R1 `{10001, 10002}` and record R2 `{10002, 10003}` for Customer AS 10 present at once, a Reset Query MUST yield a single ASPA PDU (`Flags=1`) carrying the union `{10001, 10002, 10003}` in increasing order with no duplicate — never two PDUs for the same Customer AS. When a contributing record changes (R2 replaced by R2' `{10004}`, making the union `{10001, 10002, 10004}`), the Serial Query response MUST carry a single replacement announcement with the new merged list and no prior withdrawal; only if the union becomes empty is a single withdrawal (`Flags=0`, `Length=12`) sent. The merged announcement must still satisfy the ASPA PDU constraints: at least one provider, unique and in increasing numeric order, and no AS 0 in a multi-provider PDU (otherwise Error Code 9).

---

### 5.12-7-a - `aspa-delta-simple-change-adding-provider`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for an existing Customer AS to
which one new Provider AS was added in the single serial increment being queried,
with the updated complete provider list in ascending numerical order, replacing
the previous record at the router.

---

### 5.12-7-b - `aspa-delta-simple-change-removing-provider`

**Description:**
This test checks that during a simple incremental update, the cache correctly delivers a replacement ASPA announcement PDU for an existing Customer AS from which one Provider AS was removed in the single serial increment being queried, with the updated complete provider list reflecting the removal and in ascending numerical order.

---

### 5.12-7-c - `aspa-delta-bulk-change-adding-provider`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers a replacement ASPA announcement PDU for a Customer AS whose provider list was extended with one or more new Provider AS entries within the queried serial range, with the updated and complete provider list in ascending numerical order, replacing the previously announced record at the router.

---

### 5.12-7-d - `aspa-delta-bulk-change-removing-provider`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers a replacement ASPA announcement PDU for a Customer AS whose provider list was reduced by the removal of one or more Provider AS entries within the queried serial range, with the updated and complete provider list reflecting the removal, replacing the previously announced record at the router.

---

### 5.12-8-a - `aspa-delta-simple-change-adding-customer`

**Description:**
This test checks that during a simple incremental update (Serial Query response covering a single serial increment), the cache correctly delivers an ASPA announcement PDU for a newly added Customer AS, with the Flags field set to 1 (announce) and containing the complete initial provider list in ascending order.

---

### 5.12-8-b - `aspa-delta-bulk-change-adding-customer`

**Description:**
This test checks that during a bulk incremental update (Serial Query response covering multiple serial increments), the cache correctly delivers an ASPA announcement PDU for a Customer AS that was newly added to the RPKI dataset within the queried serial range, with the Flags field set to 1 (announce) and containing the complete provider list as it exists at the cache's current serial.

---

### 5.12-9-a - `aspa-delta-simple-change-removing-customer`

**Description:**
This test checks that during a simple incremental update, the cache correctly delivers an ASPA withdrawal PDU for a Customer AS that was entirely removed in the single serial increment being queried, with the Flags field set to 0 (withdraw), no Provider list, and PDU Length equal to 12.

---

### 5.12-9-b - `aspa-delta-bulk-change-removing-customer`

**Description:**
This test checks that during a bulk incremental update, the cache correctly delivers an ASPA withdrawal PDU for a Customer AS that was entirely removed from the RPKI dataset within the queried serial range, with the Flags field set to 0 (withdraw), only the Customer AS Number present, no Provider list, and the PDU Length equal to 12.

---

### 7-1 - `supported-version-2`

**Description:**
This test checks that the cache correctly establishes a session at protocol version 2 when a router sends an initial query with Protocol Version field set to `2`, responds with a Cache Response at version `2`, and supports the full feature set of version 2 including ASPA PDUs throughout the session.

---

### 7-3-a - `supported-version-0`

**Description:**
This test checks that the cache correctly establishes a session at protocol version 0 when a router sends an initial Reset Query or Serial Query with Protocol Version field set to `0`, responding with a Cache Response at version `0` and conducting the entire subsequent exchange using only PDUs with the version 0 format, without including version-2-only features such as ASPA PDUs.

---

### 7-3-b - `supported-version-1`

**Description:**
This test checks that the cache correctly establishes a session at protocol version 1 when a router sends an initial query with Protocol Version field set to `1`, responds with a Cache Response at version `1`, and uses only PDUs compatible with version 1 for the duration of the session, omitting ASPA PDUs which are exclusive to version 2.

---

### 7-4 - `unsupported-version`

**Description:**
This test checks that the cache correctly rejects a version negotiation attempt when a router sends an initial query with a Protocol Version that the cache does not support — specifically a version higher than the cache's maximum supported version — by responding with an Error Report PDU carrying Error Code 4 ("Unsupported Protocol Version") at the cache's own highest supported version, and that the router can then retry at a lower version.

---

### 7-12 - `unexpected-version`

**Description:**
This test checks that once a protocol version has been successfully negotiated and the session is considered open, the cache drops the session and sends an Error Report PDU with Error Code 8 ("Unexpected Protocol Version") if it subsequently receives any PDU carrying a Protocol Version field that differs from the negotiated version, except when that PDU is itself an Error Report PDU.

---

### 8.4-2 - `reset-query-with-no-data-available`

**Description:**
This test checks that the cache responds to a Reset Query with an Error Report PDU indicating that no data is available — rather than a Cache Response followed by an empty payload set — when the cache has not yet successfully built or recovered its RPKI dataset, for example immediately after a restart before the first validated fetch from the Global RPKI completes.

---

### 9-1-a - `fragmented-reset-query`

**Description:**
This test checks that the cache correctly handles a Reset Query PDU that arrives fragmented across multiple TCP segments — i.e., the complete 8-octet PDU is not received in a single read — by reassembling it correctly before processing, and responding with the expected Cache Response followed by the full active dataset and an End of Data PDU, without errors caused by partial PDU processing.

---

### 9-1-b - `fragmented-serial-query`

**Description:**
This test checks that the cache correctly handles a Serial Query PDU that arrives fragmented across multiple TCP segments — i.e., the complete 12-octet PDU is split across at least two reads — by fully reassembling it before processing, and responding with the expected incremental update (or Cache Reset if the serial is outside the window) without errors attributable to partial PDU reception.

---

### 11.2 - `pdu-ordering`

**Description:**
This test verifies the cache fetches Cache Response PDU streams in the total ordering defined in section 11.2. Every byte in each PDU type's abstract representation is assigned a PDU permutation with a small value, and another one with a large value. Thus, the test ensures each byte is properly sorted not only in relationship with the others, but also in relationship with itself. The input RDs are randomly shuffled before being fed to Barry, which means the RP is forced to sort a different input every time the test is run.

---

### 12-2.2 - `corrupt-data-pdu`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 0 ("Corrupt Data"). The simulated router sends an Error Report PDU with code 0 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition that would lead a router to detect corruption (the canonical one being a Session ID in a cache-originated PDU, e.g. a Cache Response, End of Data, or Serial Notify, that does not match the Session ID established for the session, where the detecting party MUST terminate with code 0), nor does it assert that a router actually encountered it. What is under test is that the cache server correctly identifies the error the router is reporting, records it in its log as a client-reported error (with Error Code 0) so that an operator can act on it, and closes the connection on receipt — without replying with an Error Report PDU of its own (section 5.11). This complements test 5.1-2.10, which exercises the same code in the opposite direction (the cache detecting a bad Session ID in a Serial Query sent by the router).

---

### 12-2.12 - `unsupported-pdu-type`

**Description:**
This test checks that the cache correctly handles receiving a PDU whose PDU Type field contains a value not recognized or supported in the negotiated protocol version, by responding with an appropriate Error Report PDU and either terminating or recovering the session gracefully, without crashing or entering an undefined state.

---

### 12-2.14 - `withdrawal-of-unknown-record-pdu`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 6 ("Withdrawal of Unknown Record"). The simulated router sends an Error Report PDU with code 6 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition (a withdrawal PDU, Flags lowest-order bit = 0, for a record absent from the router's database: an unknown `{Prefix, Len, Max-Len, AS}` tuple for an IPvX PDU, an unknown `{SKI, AS, Subject Public Key}` for a Router Key PDU, or an unknown Customer AS for an ASPA PDU), and it does not assert that a router actually received such an unmatched withdrawal. What is under test is that the cache server correctly identifies the code 6 error the router is reporting, records it in its log as a client-reported error so that an operator can act on it, and closes the connection on receipt.

---

### 12-2.16 - `duplicate-announcement-received-pdu`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 7 ("Duplicate Announcement Received"). The simulated router sends an Error Report PDU with code 7 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition (an announcement PDU, Flags lowest-order bit = 1, for a record already active in the router: a duplicate IPvX VRP `{Prefix, Len, Max-Len, AS}`, a duplicate Router Key `{SKI, AS, Subject Public Key}`, or a duplicate announcement/withdrawal within a single Serial Query response), and it does not assert that a router actually held a duplicate. What is under test is that the cache server correctly identifies the code 7 error the router is reporting, records it in its log as a client-reported error so that an operator can act on it, and closes the connection on receipt.

---

### 12-2.20 - `aspa-provider-list-error-pdu`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 9 ("ASPA Provider List Error"). The simulated router sends an Error Report PDU with code 9 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition (a malformed ASPA announcement: an announcement, Flags lowest-order bit = 1, carrying zero Provider Autonomous System Numbers, or a multi-provider announcement that includes AS 0 — note that a *single*-provider announcement carrying AS 0 is valid, expressing a customer with no providers, and would not trigger the error), and it does not assert that a router actually received such a PDU. What is under test is that the cache server correctly identifies the code 9 error the router is reporting, records it in its log as a client-reported error so that an operator can act on it, and closes the connection on receipt.

---

### 12-2.24 - `ordering-error-pdu`

**Description:**
This test validates the cache server's handling of a client-reported Error Code 11 ("Ordering Error"). The simulated router sends an Error Report PDU with code 11 directly to the cache; the scenario is *injected*, not *provoked* — the harness does not reconstruct the genuine condition (payload PDUs delivered out of the total ordering mandated by section 11.2, e.g. an announcement appearing after a withdrawal, a PDU of a lower integer PDU type appearing after one of a higher type, or two same-type PDUs out of their defined sort order), and it does not assert that a router actually observed an ordering violation — a check that is itself optional for routers. What is under test is that the cache server correctly identifies the code 11 error the router is reporting, records it in its log as a client-reported error so that an operator can act on it, and closes the connection on receipt.

---

*End of draft-ietf-sidrops-8210bis-25 test suite — 41 test cases*
