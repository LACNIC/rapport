# Rapport – Test Suite: draft-ietf-sidrops-8210bis
## The RPKI to Router Protocol, Version 2
### Reference version: draft-ietf-sidrops-8210bis-25

> **Scope:** Tests derived from this draft focus on the RPKI-to-Router (RTR)
> protocol that a cache uses to deliver validated RPKI data — IPv4/IPv6 prefix
> VRPs, Router Keys, and ASPA records — to routers. The cache server under test must
> correctly implement protocol version negotiation, PDU structure enforcement,
> session and serial management, incremental and full update sequences, and the
> specific semantics of ASPA and prefix payload PDUs including their delta
> (announce/withdraw) mechanics.

---

## Key Concepts

| Concept | Section | Impact on cache under test |
|---|---|---|
| Protocol versions 0, 1, and 2 coexist; version is negotiated per session | section 7 | Cache must downgrade or reject based on router's offered version |
| Session ID binds a Serial Number space to one cache instance | section 5.1, section 2 | Session ID mismatch must cause Error Report and session teardown |
| Serial Number is a 32-bit strictly increasing counter; wrap-around applies | section 2, section 5.1 | Cache Reset must be issued when serial is outside the available window |
| Reset Query requests the full active database; Serial Query requests incremental changes | section 5.3, section 5.4 | Cache must respond correctly to each query type |
| Cache Has No Data Available is signaled with Error Report PDU | section 8.4 | Cache must not respond with payload PDUs when data is not yet available |
| PDU Length MUST NOT exceed 65,535 octets | section 5.1 | Fragmented or oversized PDUs must be handled or rejected |
| ASPA PDU announcement MUST contain at least one Provider AS; withdrawal MUST have no Provider list and Length == 12 | section 5.12 | Malformed ASPA PDUs must trigger Error Code 9 |
| For a given Customer AS, the router MUST see at most one active ASPA from a cache at any time | section 5.12 | Cache must merge multiple RPKI ASPA records into one PDU |
| Cache MUST merge announce/withdraw for same prefix/AS into minimal VRP | section 5.6 | Delta changes must be coalesced before delivery |
| Flags field lowest-order bit: 1 = announce, 0 = withdraw | section 5.1 | Incorrect flag values produce wrong router state |

---

## Test Cases

---

## Category 1 – Protocol Version Negotiation

---

### 01 - `supported-version-0`

**Description:**
This test checks that the cache correctly establishes a session at protocol
version 0 when a router sends an initial Reset Query or Serial Query with
Protocol Version field set to `0`, responding with a Cache Response at version
`0` and conducting the entire subsequent exchange using only PDUs with the
version 0 format, without including version-2-only features such as ASPA PDUs.

**Related sections:** section 7 (if a cache which supports version C receives a
query with Protocol Version Q < C, and the cache can support version Q, the cache
MUST establish the session at protocol version Q and respond with a Cache Response
of that Protocol Version; all PDUs MUST have the negotiated lower version number
in their version fields)

---

### 02 - `supported-version-1`

**Description:**
This test checks that the cache correctly establishes a session at protocol
version 1 when a router sends an initial query with Protocol Version field set
to `1`, responds with a Cache Response at version `1`, and uses only PDUs
compatible with version 1 for the duration of the session, omitting ASPA PDUs
which are exclusive to version 2.

**Related sections:** section 7 (if the cache can support version Q, the cache
MUST establish the session at protocol version Q and respond with a Cache Response
of that Protocol Version; in any downgraded combination, new features of the
higher version will not be available)

---

### 03 - `supported-version-2`

**Description:**
This test checks that the cache correctly establishes a session at protocol
version 2 when a router sends an initial query with Protocol Version field set
to `2`, responds with a Cache Response at version `2`, and supports the full
feature set of version 2 including ASPA PDUs throughout the session.

**Related sections:** section 7 (once a router has established a transport
connection to a cache, it MUST attempt to open a session by issuing a Reset Query
or Serial Query with the highest version the router implements; if the cache
supports that version, it responds with a Cache Response of that version and the
session is considered open)

---

### 04 - `unsupported-version`

**Description:**
This test checks that the cache correctly rejects a version negotiation attempt
when a router sends an initial query with a Protocol Version that the cache
does not support — specifically a version higher than the cache's maximum
supported version — by responding with an Error Report PDU carrying Error Code 4
("Unsupported Protocol Version") at the cache's own highest supported version,
and that the router can then retry at a lower version.

**Related sections:** section 7 (if the cache which supports version C receives a
query of version Q > C, the cache MUST send an Error Report with Protocol Version
C and Error Code 4; the router SHOULD send another query with Protocol Version Q
equal to the version C in the Error Report)

---

### 05 - `unexpected-version`

**Description:**
This test checks that once a protocol version has been successfully negotiated
and the session is considered open, the cache drops the session and sends an
Error Report PDU with Error Code 8 ("Unexpected Protocol Version") if it
subsequently receives any PDU carrying a Protocol Version field that differs from
the negotiated version, except when that PDU is itself an Error Report PDU.

**Related sections:** section 7 (if either party receives a PDU for a different
Protocol Version once negotiation completes, that party MUST drop the session;
unless the PDU containing the unexpected Protocol Version was itself an Error
Report PDU, the party dropping the session SHOULD send an Error Report with
Error Code 8, "Unexpected Protocol Version")

---

### 06 - `unsupported-pdu-type`

**Description:**
This test checks that the cache correctly handles receiving a PDU whose PDU Type
field contains a value not recognized or supported in the negotiated protocol
version, by responding with an appropriate Error Report PDU and either terminating
or recovering the session gracefully, without crashing or entering an undefined
state.

**Related sections:** section 5.1 (PDU Type is an 8-bit unsigned integer denoting
the type of the PDU; the protocol is extensible to support new PDUs with new
semantics), section 5.11 (Error Report PDU is used by either party to report an
error to the other), section 12 (Error Codes — implementations should report
unrecognized PDU types).

---

## Category 2 – PDU Structure and Fragmentation

---

### 07 - `fragmented-reset-query`

**Description:**
This test checks that the cache correctly handles a Reset Query PDU that arrives
fragmented across multiple TCP segments — i.e., the complete 8-octet PDU is not
received in a single read — by reassembling it correctly before processing, and
responding with the expected Cache Response followed by the full active dataset
and an End of Data PDU, without errors caused by partial PDU processing.

**Related sections:** section 5.4 (Reset Query PDU has a fixed Length=8; the cache
responds with a Cache Response followed by zero or more payload PDUs and an End of
Data PDU), section 9 (the transport-layer session carries binary PDUs in a
persistent reliable session; a cache SHOULD NOT use a separate TCP segment for
each PDU, implying routers must handle PDUs that span segments).

---

### 08 - `fragmented-serial-query`

**Description:**
This test checks that the cache correctly handles a Serial Query PDU that arrives
fragmented across multiple TCP segments — i.e., the complete 12-octet PDU is split
across at least two reads — by fully reassembling it before processing, and
responding with the expected incremental update (or Cache Reset if the serial is
outside the window) without errors attributable to partial PDU reception.

**Related sections:** section 5.3 (Serial Query PDU has a fixed Length=12; the
cache replies with a Cache Response if it has a record of changes since the Serial
Number specified by the router, followed by zero or more payload PDUs and an End
of Data PDU), section 9 (transport carries binary PDUs in a persistent reliable
session)

---

## Category 3 – Query Handling and Session Management

---

### 09 - `reset-query-with-no-data-available`

**Description:**
This test checks that the cache responds to a Reset Query with an Error Report PDU
indicating that no data is available — rather than a Cache Response followed by an
empty payload set — when the cache has not yet successfully built or recovered its
RPKI dataset, for example immediately after a restart before the first validated
fetch from the Global RPKI completes.

**Related sections:** section 8.4 (the cache may respond to a Reset Query with an
Error Report PDU informing the router that the cache cannot supply any update at
all; the most likely cause is that the cache has lost state and has not yet
recovered; a router is more likely to see this when it initially connects and
issues a Reset Query while the cache is still rebuilding its database)

---

### 11 - `serial-query-with-incorrect-session-id`

**Description:**
This test checks that the cache detects a Session ID mismatch when a Serial Query
arrives carrying a Session ID that does not match the Session ID previously
established for the session, and responds by immediately terminating the session
with an Error Report PDU carrying Error Code 0 ("Corrupt Data"), causing the
router to flush all data learned from that cache.

**Related sections:** section 5.1 (if either the router or the cache finds that
the value of the Session ID it is using is not the same as the other's, the party
which detects the mismatch MUST immediately terminate the session with an Error
Report PDU with code 0, "Corrupt Data", and the router MUST flush all data learned
from that cache), section 5.3 (per section 5.1, if the Serial Query contains a
Session ID that is not equal to that previously established, the cache terminates
the session with an Error Report PDU with code 0)

---

### 12 - `serial-query-with-serial-equal-to-server-serial`

**Description:**
This test checks that the cache correctly responds to a Serial Query whose Serial
Number field is equal to the cache's current Serial Number — meaning the router
is already fully up to date — by sending a Cache Response followed immediately
by an End of Data PDU with no intervening payload PDUs, correctly signaling that
there are no changes to deliver.

**Related sections:** section 5.3 (the cache replies to a Serial Query with all
announcements and withdrawals which have occurred since the Serial Number
specified; this may be the null set, in which case the End of Data PDU is still
sent), section 4 (the cache responds to the Serial Query with all data changes
which took place since the given Serial Number; this may be the null set, in which
case the End of Data PDU is still sent)

---

### 13 - `serial-query-with-serial-outside-of-window`

**Description:**
This test checks that the cache responds to a Serial Query whose Serial Number
refers to a point in history that is no longer available in the cache's incremental
update window — because the cache has since cleaned up old delta data or the
router waited too long between polls — by sending a Cache Reset PDU, informing
the router that it cannot provide an incremental update from that serial and must
fall back to a Reset Query.

**Related sections:** section 5.9 (the cache sends a Cache Reset PDU in response
to a Serial Query in order to inform the router that the cache cannot provide an
incremental update starting from the Serial Number specified by the router),
section 8.3 (No Incremental Update Available: the cache may respond to a Serial
Query with a Cache Reset, informing the router that the cache cannot supply an
incremental update from the specified Serial Number)

---

## Category 4 – ASPA PDU Delta Mechanics

---

### 14 - `aspa-delta-simple-change-adding-customer`

**Description:**
This test checks that during a simple incremental update (Serial Query response
covering a single serial increment), the cache correctly delivers an ASPA
announcement PDU for a newly added Customer AS, with the Flags field set to 1
(announce) and containing the complete initial provider list in ascending order.

**Related sections:** section 5.12 (the Flags field set to 1 indicates the
announcement of a new ASPA record; an ASPA announcement PDU MUST contain at
least one Provider Autonomous System Number), section 8.2 (Typical Exchange:
the cache sends all data newer than the serial in the Serial Query)

---

### 15 - `aspa-delta-simple-change-adding-provider`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for an existing Customer AS to
which one new Provider AS was added in the single serial increment being queried,
with the updated complete provider list in ascending numerical order, replacing
the previous record at the router.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer AS replaces the previous
one; the cache MUST deliver the complete data of an ASPA record in a single ASPA
PDU; each Provider AS Number MUST be unique and in increasing numeric order)

---

### 16 - `aspa-delta-simple-change-removing-customer`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers an ASPA withdrawal PDU for a Customer AS that was entirely removed
in the single serial increment being queried, with the Flags field set to 0
(withdraw), no Provider list, and PDU Length equal to 12.

**Related sections:** section 5.12 (if the announce/withdraw flag is set to 0,
the entire ASPA record MUST be removed from the router; there MUST be no Provider
list and the PDU Length MUST be 12)

---

### 17 - `aspa-delta-simple-change-removing-provider`

**Description:**
This test checks that during a simple incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for an existing Customer AS from
which one Provider AS was removed in the single serial increment being queried,
with the updated complete provider list reflecting the removal and in ascending
numerical order.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer AS replaces the previous
one; the cache MUST deliver the complete data of an ASPA record in a single ASPA
PDU)

---

### 18 - `aspa-delta-bulk-change-adding-customer`

**Description:**
This test checks that during a bulk incremental update (Serial Query response
covering multiple serial increments), the cache correctly delivers an ASPA
announcement PDU for a Customer AS that was newly added to the RPKI dataset
within the queried serial range, with the Flags field set to 1 (announce) and
containing the complete provider list as it exists at the cache's current serial.

**Related sections:** section 5.12 (the ASPA PDU Flags field set to 1 indicates
the announcement of a new ASPA record or a replacement for a previously announced
record; receipt of an ASPA PDU announcement when the router already has an ASPA
PDU with the same Customer AS replaces the previous one), section 5.3 (the cache
MUST return the minimum set of changes needed to bring the router into sync;
multiple changes between serial numbers MUST be merged)

---

### 19 - `aspa-delta-bulk-change-adding-provider`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for a Customer AS whose provider
list was extended with one or more new Provider AS entries within the queried
serial range, with the updated and complete provider list in ascending numerical
order, replacing the previously announced record at the router.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer Autonomous System Number
from that cache replaces the previous one; the cache MUST deliver the complete
data of an ASPA record in a single ASPA PDU; Provider AS Numbers MUST be in
increasing numeric order), section 5.3 (the cache MUST merge multiple changes to
present the simplest possible view)

---

### 20 - `aspa-delta-bulk-change-removing-customer`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an ASPA withdrawal PDU for a Customer AS that was entirely removed from
the RPKI dataset within the queried serial range, with the Flags field set to 0
(withdraw), only the Customer AS Number present, no Provider list, and the PDU
Length equal to 12.

**Related sections:** section 5.12 (if the announce/withdraw flag is set to 0,
the entire ASPA record from that cache for that Customer AS MUST be removed from
the router; in this case the Customer AS MUST be provided, there MUST be no
Provider list, and the PDU Length MUST be 12)

---

### 21 - `aspa-delta-bulk-change-removing-provider`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers a replacement ASPA announcement PDU for a Customer AS whose provider
list was reduced by the removal of one or more Provider AS entries within the
queried serial range, with the updated and complete provider list reflecting the
removal, replacing the previously announced record at the router.

**Related sections:** section 5.12 (receipt of an ASPA PDU announcement when the
router already has an ASPA PDU with the same Customer AS replaces the previous
one; the cache MUST deliver the complete data of an ASPA record in a single ASPA
PDU), section 5.3 (the cache MUST merge changes to present the simplest possible
view)

---

## Category 5 – IPv4 Prefix PDU Delta Mechanics

---

### 22 - `ipv4-prefix-delta-simple-change-adding-prefix`

**Description:**
This test checks that during a simple incremental update covering a single serial
increment, the cache correctly delivers an IPv4 Prefix PDU with the Flags field
set to 1 (announce) for a newly added IPv4 VRP, with all fields correctly populated
including a Prefix whose unused bits are zeroed, and that the cache has not
delivered a prior withdrawal for the same tuple in the same delta.

**Related sections:** section 5.6 (IPv4 Prefix PDU; announcement flag = 1; the
cache server MUST set the remaining bits of the Prefix to zero; the cache MUST
ensure that it has told the router to have one and only one IPv4 VRP for a unique
{Prefix, Len, Max-Len, AS} at any one point in time), section 8.2 (Typical
Exchange)

---

### 23 - `ipv4-prefix-delta-simple-change-updating-as`

**Description:**
This test checks that during a simple incremental update, the cache correctly
represents a change to the Autonomous System Number associated with an existing
IPv4 prefix by delivering a withdrawal PDU for the old {Prefix, Len, Max-Len,
old-AS} tuple followed by an announcement PDU for the new {Prefix, Len, Max-Len,
new-AS} tuple, and that the cache does not attempt to deliver these as a single
in-place update, since the {Prefix, Len, Max-Len, AS} tuple is the primary key
for VRP identity.

**Related sections:** section 5.6 (a withdrawal deletes one previously announced
Prefix PDU with the exact same Prefix, Length, Max-Len, and AS; changing the AS
effectively means withdrawing the old entry and announcing a new one), section 5.3
(the cache MUST merge changes to present the simplest possible view), section 11.2.1
(caches MUST send all withdraw PDUs before any announce PDUs)

---

### 24 - `ipv4-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv4 Prefix PDU with the Flags field set to 1 (announce) for each
IPv4 VRP that was newly added to the RPKI dataset within the queried serial range,
with correct Prefix, Prefix Length, Max Length, and Autonomous System Number
fields, and that the cache merges multiple changes for the same {Prefix, Len,
Max-Len, AS} tuple into at most one announcement.

**Related sections:** section 5.6 (IPv4 Prefix PDU; the lowest-order bit of the
Flags field is 1 for an announcement), section 5.3 (the cache MUST return the
minimum set of changes; if a prefix underwent multiple changes, the cache MUST
merge those changes; the data stream will include at most one withdrawal followed
by at most one announcement)

---

### 25 - `ipv4-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv4 Prefix PDU with the Flags field set to 0 (withdraw) for each
IPv4 VRP that was removed from the RPKI dataset within the queried serial range,
with the exact same {Prefix, Len, Max-Len, AS} tuple as the previously announced
record, effectively deleting the router's stored VRP entry.

**Related sections:** section 5.6 (the lowest-order bit of the Flags field is 0
for a withdrawal; a withdraw effectively deletes one previously announced Prefix
PDU with the exact same Prefix, Length, Max-Len, and AS), section 5.3 (the cache
MUST merge changes; if all changes cancel out, the data stream will not mention
the prefix/AS at all)

---

## Category 6 – IPv6 Prefix PDU Delta Mechanics

---

### 26 - `ipv6-prefix-delta-simple-change-adding-prefix`

**Description:**
This test checks that during a simple incremental update covering a single serial
increment, the cache correctly delivers an IPv6 Prefix PDU with the Flags field
set to 1 (announce) for a newly added IPv6 VRP, with all 128-bit prefix bits
beyond the prefix length zeroed, and that the cache ensures the router holds one
and only one VRP for the unique {Prefix, Len, Max-Len, AS} tuple at that point in
time.

**Related sections:** section 5.7 (IPv6 Prefix PDU; the behaviour for IPv4 Prefix
PDU applies, including zeroing unused prefix bits and the one-and-only-one VRP
constraint), section 8.2 (Typical Exchange)

---

### 27 - `ipv6-prefix-delta-simple-change-updating-as`

**Description:**
This test checks that during a simple incremental update, the cache correctly
represents a change to the Autonomous System Number associated with an existing
IPv6 prefix by delivering a withdrawal PDU for the old {Prefix, Len, Max-Len,
old-AS} tuple followed by an announcement PDU for the new {Prefix, Len, Max-Len,
new-AS} tuple, and that the withdrawal is delivered before the announcement in
accordance with the ordering requirements for IP Prefix PDUs.

**Related sections:** section 5.7 (behaviour for IPv6 Prefix PDU mirrors that of
IPv4 Prefix PDU; a withdrawal deletes one previously announced Prefix PDU with the
exact same Prefix, Length, Max-Len, and AS; changing the AS requires a withdrawal
and a new announcement), section 11.2.1 (IP Prefix PDUs: caches MUST send all
withdraw PDUs before any announce PDUs)

---

### 28 - `ipv6-prefix-delta-bulk-change-adding-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv6 Prefix PDU with the Flags field set to 1 (announce) for each
IPv6 VRP newly added within the queried serial range, with correct 128-bit Prefix,
Prefix Length (0..128), Max Length (0..128), and Autonomous System Number fields,
and with unused prefix bits zeroed, merging multiple changes for the same tuple
into at most one announcement.

**Related sections:** section 5.7 (IPv6 Prefix PDU; the behaviour specified for
the IPv4 Prefix PDU is also applicable to the IPv6 Prefix PDU; PDU Length=32),
section 5.3 (the cache MUST return the minimum set of changes and MUST merge
multiple changes for the same prefix/AS)

---

### 29 - `ipv6-prefix-delta-bulk-change-removing-prefix`

**Description:**
This test checks that during a bulk incremental update, the cache correctly
delivers an IPv6 Prefix PDU with the Flags field set to 0 (withdraw) for each
IPv6 VRP removed within the queried serial range, with the exact same {Prefix,
Len, Max-Len, AS} tuple as the previously announced record, effectively deleting
the router's stored IPv6 VRP entry.

**Related sections:** section 5.7 (the behaviour specified for the IPv4 Prefix PDU
is also applicable to the IPv6 Prefix PDU; a withdrawal deletes one previously
announced Prefix PDU with the exact same fields), section 5.3 (if all changes for
a prefix/AS cancel out, the data stream will not mention it at all)

---

*End of draft-ietf-sidrops-8210bis-25 test suite — 29 test cases across 6 categories*
